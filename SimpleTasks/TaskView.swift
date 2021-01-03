import ComposableArchitecture
import SwiftUI

enum TaskAction {
    case editTapped
}

struct TaskEnvironment {

}

let taskReducer = Reducer<Task, TaskAction, TaskEnvironment> { state, action, environment in
    return .none
}

struct TaskView: View {
    let store: Store<Task, TaskAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack(alignment: .leading) {
                Text(viewStore.title)
                    .multilineTextAlignment(.leading)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationBarTitle("Task Details")
            .navigationBarItems(
                trailing: Button("Edit") { viewStore.send(.editTapped) }
            )
        }
    }
}


struct TaskView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store(
            initialState: Task(id: 1, title: "Test Test Test", dueBy: Date().timeIntervalSince1970, priority: .medium),
            reducer: taskReducer,
            environment: TaskEnvironment()
        )
        NavigationView {
            TaskView(store: store)
        }
    }
}
