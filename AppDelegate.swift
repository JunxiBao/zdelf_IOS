import UIKit
import AudioToolbox

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let launchViewController = LaunchViewController()
        window?.rootViewController = launchViewController
        window?.makeKeyAndVisible()
        return true
    }
}

class LaunchViewController: UIViewController {
    let logo = UIImageView(image: UIImage(named: "logo"))
    let mainVC = WebViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 渐变背景
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.systemPurple.cgColor, UIColor.systemIndigo.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds
        view.layer.addSublayer(gradient)

        // 设置 logo
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.alpha = 0
        view.addSubview(logo)

        NSLayoutConstraint.activate([
            logo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logo.widthAnchor.constraint(equalToConstant: 100),
            logo.heightAnchor.constraint(equalToConstant: 100)
        ])

        // 提前加载主控制器视图
        _ = mainVC.view

        // 动画效果：淡入 + 弹跳 + 缩放 + 过渡
        UIView.animate(withDuration: 1.0, delay: 0.3, options: [.curveEaseOut], animations: {
            self.logo.alpha = 1
            self.logo.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.6, animations: {
                self.logo.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                UIView.animate(withDuration: 0.8, animations: {
                    self.logo.transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
                    self.logo.alpha = 0
                }) { _ in
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = scene.windows.first {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        UIView.transition(with: window, duration: 0.7, options: .transitionCrossDissolve, animations: {
                            window.rootViewController = self.mainVC
                        })
                    }
                }
            }
        }
    }
}
