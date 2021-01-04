import ComposableArchitecture
import SwiftUI
import SwiftUIRefresh

// MARK: - Tasks domain

struct TasksState: Equatable {
    var isLoading: Bool = false
    var isRefreshing: Bool = false
    var tasks: IdentifiedArrayOf<Task> = []
    var currentPage: Int = 0
    var canLoadNextPage: Bool = true

    var alert: AlertState<TasksAction>? = nil
}

enum TasksAction: Equatable {
    case logoutButtonTapped
    case refreshTriggered
    case viewAppeared
    case scrolledAtBottom
    case addButtonTapped
    case tasksResponse(Result<TasksResponse, TasksClient.Failure>)
    case delete(IndexSet)
    case deleteFinished
    case deleteFailed(Task, String)
    case alertDismissed
}

struct TasksEnvironment {
    var tasksClient: TasksClient
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

// MARK: - Tasks reducer

let tasksReducer = Reducer<TasksState, TasksAction, TasksEnvironment> { state, action, environment in
    struct TasksId: Hashable {}
    struct TaskDeleteId: Hashable {}

    switch action {
    case .logoutButtonTapped:
        return .none
    case .refreshTriggered:
        state.isRefreshing = true
        return environment.tasksClient.tasks(1)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(TasksAction.tasksResponse)
            .cancellable(id: TasksId(), cancelInFlight: true)
    case .viewAppeared:
        if state.tasks.isEmpty {
            return Effect(value: TasksAction.scrolledAtBottom)
        }
        return .none
    case .scrolledAtBottom:
        if state.canLoadNextPage, !state.isLoading, !state.isRefreshing {
            state.isLoading = true
            return environment.tasksClient.tasks(state.currentPage + 1)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(TasksAction.tasksResponse)
                .cancellable(id: TasksId(), cancelInFlight: true)
        }
        return .none
    case .addButtonTapped:
        return .none
    case let .tasksResponse(.success(response)):
        state.isRefreshing = false
        state.isLoading = false
        state.currentPage = response.meta.current
        state.canLoadNextPage = (Double(response.meta.count) / Double(response.meta.limit)) > Double(response.meta.current)
        if response.meta.current == 1 {
            state.tasks = response.tasks
        } else {
            state.tasks.append(contentsOf: response.tasks)
        }

        return .none
    case let .tasksResponse(.failure(failure)):
        state.isRefreshing = false
        state.isLoading = false
        state.alert = AlertState(title: LocalizedStringKey(failure.message))
        return .none
    case let .delete(indexSet):
        if let offset = indexSet.reversed().first {
            let task = state.tasks.remove(at: offset)
            return environment.tasksClient.deleteTask(task.id)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map {
                    switch $0 {
                    case .success():
                        return .deleteFinished
                    case let .failure(failure):
                        return .deleteFailed(task, failure.message)
                    }
                }
        }
        return .none
    case let .deleteFailed(task, message):
        state.tasks.insert(task, at: 0)
        state.alert = AlertState(title: LocalizedStringKey(message))
        return .none
    case .alertDismissed:
        state.alert = nil
        return .none
    case .deleteFinished:
        return .none
    }
}

// MARK: - Tasks view

struct TasksView: View {
    let store: Store<TasksState, TasksAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack(alignment: .leading) {
                List {
                    ForEach(viewStore.tasks) { task in
                        NavigationLink(
                            task.title,
                            destination: TaskView(
                                store: Store(initialState: task, reducer: taskReducer, environment: TaskEnvironment())
                            )
                        )
                        .onAppear(perform: {
                            if viewStore.tasks.last == task {
                                viewStore.send(.scrolledAtBottom)
                            }
                        })
                    }
                    .onDelete { viewStore.send(.delete($0)) }

                    if viewStore.isLoading {
                        HStack {
                            Spacer()
                            ActivityIndicator()
                            Spacer()
                        }
                    }
                }
                .pullToRefresh(
                    isShowing: viewStore.binding(get: { $0.isRefreshing }, send: .refreshTriggered)
                ) {}
            }
            .navigationBarTitle("Tasks")
            .navigationBarItems(
                leading: Button("Logout") { viewStore.send(.logoutButtonTapped) },
                trailing: NavigationLink(
                    destination: NewTaskView(),
                    label: {
                        Text("Add")
                    })
            )
            .onAppear(perform: {
                viewStore.send(.viewAppeared)
            })
            .alert(self.store.scope(state: \.alert), dismiss: .alertDismissed)
        }
    }
}
