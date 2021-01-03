import ComposableArchitecture
import SwiftUI

// MARK: - Tasks domain

struct TasksState: Equatable {
    var isLoading: Bool = false
    var isRefreshing: Bool = false
    var tasks: IdentifiedArrayOf<Task> = []

    var alert: AlertState<TasksAction>? = nil
}

enum TasksAction: Equatable {
    case logoutButtonTapped
    case refreshTriggered
    case addButtonTapped
    case tasksResponse(Result<IdentifiedArrayOf<Task>, TasksClient.Failure>)
    case alertDismissed
}

struct TasksEnvironment {
    var tasksClient: TasksClient
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

// MARK: - Tasks reducer

let tasksReducer = Reducer<TasksState, TasksAction, TasksEnvironment> { state, action, environment in
    struct TasksId: Hashable {}

    switch action {
    case .logoutButtonTapped:
        return .none
    case .refreshTriggered:
        return environment.tasksClient.tasks(1)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(TasksAction.tasksResponse)
            .cancellable(id: TasksId(), cancelInFlight: true)
    case .addButtonTapped:
        return .none
    case let .tasksResponse(.success(tasks)):
        state.tasks = tasks
        return .none
    case let .tasksResponse(.failure(failure)):
        state.alert = AlertState(title: LocalizedStringKey(failure.message))
        return .none
    case .alertDismissed:
        state.alert = nil
        return .none
    }
}.debug()

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
                    }
                }
            }
            .navigationBarTitle("Tasks")
            .navigationBarItems(
                leading: Button("Logout") { viewStore.send(.logoutButtonTapped) },
                trailing: Button("Add") { viewStore.send(.addButtonTapped) }
            )
            .onAppear(perform: {
                viewStore.send(.refreshTriggered)
            })
        }
    }
}
