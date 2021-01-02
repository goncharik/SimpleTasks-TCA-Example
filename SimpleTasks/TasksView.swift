import ComposableArchitecture
import SwiftUI

struct TasksState: Equatable {

}

enum TasksAction: Equatable {
    case logoutButtonTapped
}

struct TasksEnvironment {
    
}

let tasksReducer = Reducer<TasksState, TasksAction, TasksEnvironment> { state, action, environment in
    return .none
}

struct TasksView: View {
    let store: Store<TasksState, TasksAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack {
                Text("Hello world")
            }
            .navigationBarTitle("Tasks")
            .navigationBarItems(trailing: Button("Logout") { viewStore.send(.logoutButtonTapped) })
        }
    }
}
