import ComposableArchitecture
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

        let store = Store(
            initialState: LoginState(email: "", password: ""),
            reducer: loginReducer,
            environment: LoginEnvironment()
        )
        let loginView = LoginView(store: store)

        self.window?.rootViewController = UIHostingController(
          rootView: loginView
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
