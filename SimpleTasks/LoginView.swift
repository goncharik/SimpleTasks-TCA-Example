import ComposableArchitecture
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
    case authSucceed
    case authError(String)
}

struct LoginEnvironment {
}

// MARK: - Login reducer

let loginReducer = Reducer<LoginState, LoginAction, LoginEnvironment> { state, action, environment in
    return .none
}

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
            environment: LoginEnvironment()
        )
        LoginView(store: store)
    }
}
