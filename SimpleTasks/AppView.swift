import ComposableArchitecture
import KeychainAccess
import SwiftUI

struct AppState: Equatable {
    var login: LoginState?
    var tasks: TasksState?
}

enum AppAction: Equatable {
    case login(LoginAction)
    case tasks(TasksAction)
}

struct AppEnvironment {
    var tasksClient: TasksClient
    var keychain: Keychain
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    loginReducer.optional().pullback(
        state: \.login,
        action: /AppAction.login,
        environment: {
            LoginEnvironment(
                tasksClient: $0.tasksClient,
                mainQueue: $0.mainQueue
            )
        }
    ),
    tasksReducer.optional().pullback(
        state: \.tasks,
        action: /AppAction.tasks,
        environment: { _ in TasksEnvironment() }
    ),
    Reducer { state, action, environment in
        switch action {
        case let .login(.authResponse(.success(authToken))):
            state.tasks = TasksState()
            state.login = nil
            environment.keychain.token = authToken.token
            return .none

        case .login:
            return .none

        case .tasks(.logoutButtonTapped):
            environment.keychain.token = nil
            state.login = LoginState()
            state.tasks = nil
            return .none

        case .tasks:
            return .none
        }
    }
)

struct AppView: View {
    let store: Store<AppState, AppAction>

    @ViewBuilder public var body: some View {
        IfLetStore(self.store.scope(state: { $0.login }, action: AppAction.login)) { store in
            NavigationView {
                LoginView(store: store)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }

        IfLetStore(self.store.scope(state: { $0.tasks }, action: AppAction.tasks)) { store in
            NavigationView {
                TasksView(store: store)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
