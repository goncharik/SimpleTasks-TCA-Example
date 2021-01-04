import ComposableArchitecture
import SwiftUI

enum NewTaskStateMode: Equatable {
    case create
    case update
}

struct NewTaskState: Equatable {
    let mode: NewTaskStateMode

    var title: String = ""
    var priority: TaskPriority = .low
    var due: Date = Date(timeIntervalSinceNow: 60 * 60 * 24)

    var alert: AlertState<NewTaskAction>? = nil
    
    var isValid: Bool { !title.isEmpty }

    var isLoading: Bool

    init(_ task: Task?) {
        title = ""
        priority = .low
        due = Date(timeIntervalSinceNow: 60 * 60 * 24)
        isLoading = false
        
        if let task = task {
            mode = .update
            title = task.title
            priority = task.priority
            if let dueBy = task.dueBy {
                due = Date(timeIntervalSince1970: dueBy)
            }
        } else {
            mode = .create
        }
    }
}

enum NewTaskAction: Equatable {
    case titleChanged(String)
    case priorityPicked(TaskPriority)
    case dueByPicked(Date)
    case cancelTapped
    case saveTapped
    case saveResponse(Result<Task, TasksClient.Failure>)

    case alertDismissed
}

struct NewTaskEnvironment {
    var tasksClient: TasksClient
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

let newTaskReducer = Reducer<NewTaskState, NewTaskAction, NewTaskEnvironment> { state, action, environment in
    struct NewTaskId: Hashable {}

    switch action {
    case let .titleChanged(title):
        state.title = title
    case let .priorityPicked(priority):
        state.priority = priority
    case let .dueByPicked(date):
        state.due = date
    case .cancelTapped:
        return .cancel(id: NewTaskId())
    case .saveTapped:
        state.isLoading = true
        return environment.tasksClient.createTask(
            TaskRequest(title: state.title, dueBy: Int(state.due.timeIntervalSince1970), priority: state.priority)
        )
        .receive(on: environment.mainQueue)
        .catchToEffect()
        .map(NewTaskAction.saveResponse)
        .cancellable(id: NewTaskId(), cancelInFlight: true)
    case .saveResponse(.success):
        state.isLoading = false
        return .none
    case let .saveResponse(.failure(failure)):
        state.isLoading = false
        state.alert = AlertState(title: LocalizedStringKey(failure.message))
        return .none
    case .alertDismissed:
        state.alert = nil
        return .none
    }
    return .none
}

struct NewTaskView: View {
    let store: Store<NewTaskState, NewTaskAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            Form {
                TextField("title", text: viewStore.binding(get: \.title, send: NewTaskAction.titleChanged))
                WithViewStore(self.store.scope(state: { $0.priority }, action: NewTaskAction.priorityPicked)) {
                    priorityViewStore in
                    VStack(alignment: .leading) {
                        Text("Priority:")
                        Picker(
                            "Priority", selection: priorityViewStore.binding(send: { $0 })
                        ) {
                            ForEach(TaskPriority.allCases, id: \.self) { priority in
                                Text(priority.rawValue).tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                WithViewStore(self.store.scope(state: { $0.due }, action: NewTaskAction.dueByPicked)) {
                    dueByViewStore in
                    VStack(alignment: .leading) {
                        Text("Due date:")
                        DatePicker(
                            "Due date:",
                            selection: dueByViewStore.binding(send: { $0 }),
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                    }
                }
            }
            .disabled(viewStore.isLoading)
            .navigationBarItems(
                leading: Button("Cancel", action: { viewStore.send(.cancelTapped) }),
                trailing: Button(action: { viewStore.send(.saveTapped) }) {
                    if viewStore.isLoading {
                        ActivityIndicator()
                    } else {
                        Text("Save")
                    }
                }
                .disabled(!viewStore.isValid || viewStore.isLoading)
            )
            .navigationBarBackButtonHidden(true)
            .navigationBarTitle(
                Text(viewStore.mode == .create ? "Add" : "Edit"), displayMode: .inline
            )
            .alert(self.store.scope(state: \.alert), dismiss: .alertDismissed)
        }
    }
}

struct NewTaskView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NewTaskView(
                store:
                    Store(
                        initialState: NewTaskState(nil),
                        reducer: newTaskReducer,
                        environment: NewTaskEnvironment(tasksClient: TasksClient.mock, mainQueue: DispatchQueue.main.eraseToAnyScheduler())
                    )
            )
        }
    }
}
