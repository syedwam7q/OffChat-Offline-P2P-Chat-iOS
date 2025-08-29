import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        
        // Check if user profile is set up
        if ProfileManager.shared.isProfileSetup {
            let nav = UINavigationController(rootViewController: ChatListViewController())
            window.rootViewController = nav
        } else {
            let profileSetupVC = ProfileSetupViewController()
            profileSetupVC.delegate = self
            window.rootViewController = profileSetupVC
        }
        
        self.window = window
        window.makeKeyAndVisible()
    }
}

extension SceneDelegate: ProfileSetupDelegate {
    func profileSetupDidComplete() {
        let nav = UINavigationController(rootViewController: ChatListViewController())
        window?.rootViewController = nav
    }
}