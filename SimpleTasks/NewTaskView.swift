import ComposableArchitecture
import SwiftUI

struct NewTaskState: Equatable {

}

enum NewTaskAction: Equatable {
    case editTapped
}

struct NewTaskEnvironment {

}

let newTaskReducer = Reducer<NewTaskState, NewTaskAction, NewTaskEnvironment> { state, action, environment in
    return .none
}

struct NewTaskView: View {
    let store: Store<NewTaskState, NewTaskAction>

    var body: some View {
        Text("Hello, World!")
    }
}

struct NewTaskView_Previews: PreviewProvider {
    static var previews: some View {
        NewTaskView(store: Store(initialState: NewTaskState(), reducer: newTaskReducer, environment: NewTaskEnvironment()))
    }
}
