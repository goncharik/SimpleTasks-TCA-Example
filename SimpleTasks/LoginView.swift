import ComposableArchitecture
import KeychainAccess
import SwiftUI

// MARK: - Login domain

enum AuthType: Equatable {
    case login
    case register
}

struct LoginState: Equatable {
    var email: String
    var password: String
}

enum LoginAction: Equatable {
    case emailChanged(String)
    case passwordChanged(String)
    case logInTapped
    case registerTapped
    case authResponse(Result<AuthToken, TasksClient.Failure>)
}

struct LoginEnvironment {
    var tasksClient: TasksClient
    var keychain: Keychain
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

// MARK: - Login reducer

let loginReducer = Reducer<LoginState, LoginAction, LoginEnvironment> { state, action, environment in
    struct LoginId: Hashable {}

    if action == .logInTapped {
        return environment.tasksClient.login("sample@site.com", "0123456")
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(LoginAction.authResponse)
            .cancellable(id: LoginId(), cancelInFlight: true)
    }
    return .none
}
.debug()
// MARK: - Login View

struct LoginView: View {
    let store: Store<LoginState, LoginAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack {
                Text("Sign in").font(.title).bold().padding()
                VStack(spacing: 16) {
                    TextField(
                        "Email",
                        text: .constant("")
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                    SecureField(
                        "Password",
                        text: .constant("")
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("LOG IN", action: {})
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)

                    Button("Register", action: {})
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .padding()
                .onAppear {
                    viewStore.send(.logInTapped)
                }
            }
            .padding()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store(
            initialState: LoginState(email: "", password: ""),
            reducer: loginReducer,
            environment: LoginEnvironment(
                tasksClient: TasksClient.mock,
                keychain: Keychain.mock,
                mainQueue: DispatchQueue.main.eraseToAnyScheduler()
            )
        )
        LoginView(store: store)
    }
}
