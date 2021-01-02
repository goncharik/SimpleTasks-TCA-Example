import ComposableArchitecture
import SwiftUI

// MARK: - Login domain

enum AuthType: Equatable {
    case login
    case register
}

struct LoginState: Equatable {
    var email: String = ""
    var password: String = ""

    var isLoading: Bool = false
    var alert: AlertState<LoginAction>? = nil

    var isValidInput: Bool {
        !email.isEmpty && !password.isEmpty
    }
}

enum LoginAction: Equatable {
    case emailChanged(String)
    case passwordChanged(String)
    case logInTapped
    case registerTapped
    case authResponse(Result<AuthToken, TasksClient.Failure>)
    case alertDismissed
}

struct LoginEnvironment {
    var tasksClient: TasksClient
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

// MARK: - Login reducer

let loginReducer = Reducer<LoginState, LoginAction, LoginEnvironment> { state, action, environment in
    struct LoginId: Hashable {}
    struct RegisterId: Hashable {}
    
    switch action {
    case let .emailChanged(email):
        state.email = email
    case let .passwordChanged(password):
        state.password = password
    case .logInTapped:
        state.isLoading = true
        return environment.tasksClient.login(state.email, state.password)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(LoginAction.authResponse)
            .cancellable(id: LoginId(), cancelInFlight: true)
    case .registerTapped:
        state.isLoading = true
        return environment.tasksClient.register(state.email, state.password)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(LoginAction.authResponse)
            .cancellable(id: RegisterId(), cancelInFlight: true)
    case let .authResponse(result):
        state.isLoading = false
        switch result {
        case .success:
            ()
        case let .failure(failure):
            state.alert = AlertState(title: LocalizedStringKey(failure.message))
        }
    case .alertDismissed:
        state.alert = nil
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
                        text: viewStore.binding(get: \.email, send: LoginAction.emailChanged)
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                    SecureField(
                        "Password",
                        text: viewStore.binding(get: \.password, send: LoginAction.passwordChanged)
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("LOG IN", action: {
                        viewStore.send(.logInTapped)
                    })
                    .disabled(!viewStore.isValidInput)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)

                    Button("Register", action: {
                        viewStore.send(.registerTapped)
                    })
                    .disabled(!viewStore.isValidInput)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .padding()
            }
            .padding()
            .alert(self.store.scope(state: \.alert), dismiss: .alertDismissed)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store(
            initialState: LoginState(),
            reducer: loginReducer,
            environment: LoginEnvironment(
                tasksClient: TasksClient.mock,
                mainQueue: DispatchQueue.main.eraseToAnyScheduler()
            )
        )
        LoginView(store: store)
    }
}
