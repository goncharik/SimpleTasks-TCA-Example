import ComposableArchitecture
import KeychainAccess
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        self.window = (scene as? UIWindowScene).map(UIWindow.init(windowScene:))

        let keychain = Keychain.live
        let appState: AppState

        if keychain.token != nil {
            appState = .init(tasks: TasksState())
        } else {
            appState = .init(login: LoginState())
        }
        let store = Store(
            initialState: appState,
            reducer: appReducer,
            environment: AppEnvironment(
                tasksClient: TasksClient.live,
                keychain: Keychain.live,
                mainQueue: DispatchQueue.main.eraseToAnyScheduler()
            )
        )

        let appView = AppView(store: store)
        self.window?.rootViewController = UIHostingController(
            rootView: appView
        )

        self.window?.makeKeyAndVisible()
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        true
    }
}
