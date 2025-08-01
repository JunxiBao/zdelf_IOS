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

        // 模糊效果视图
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        view.addSubview(blurView)

        // 背景渐变 + 模糊动画
        gradient.opacity = 0
        blurView.alpha = 1
        CATransaction.begin()
        CATransaction.setAnimationDuration(1.0)
        gradient.opacity = 1
        CATransaction.commit()

        UIView.animate(withDuration: 1.2) {
            blurView.alpha = 0
        }

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

        // logo 呼吸缩放 + 轻微旋转动画序列
        UIView.animate(withDuration: 1.0, delay: 0.3, options: [.curveEaseInOut], animations: {
            self.logo.alpha = 1
            self.logo.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 1.0, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction], animations: {
                self.logo.transform = CGAffineTransform(scaleX: 1.05, y: 1.05).rotated(by: .pi / 30)
            }, completion: nil)
        }

        // 提前加载主控制器视图
        _ = mainVC.view

        // 延时切换主界面动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            self.transitionToMainScreen(blurView: blurView)
        }
    }

    func transitionToMainScreen(blurView: UIVisualEffectView) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return }

        // 先停止 logo 及脉冲动画
        logo.layer.removeAllAnimations()
        view.layer.sublayers?.forEach { layer in
            if layer is CAShapeLayer {
                layer.removeAllAnimations()
            }
        }

        // 模糊渐显过渡
        blurView.alpha = 0
        UIView.animate(withDuration: 0.8, animations: {
            self.logo.transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
            self.logo.alpha = 0
            blurView.alpha = 1
            self.view.alpha = 0
        }) { _ in
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            self.view.removeFromSuperview()
            window.rootViewController = self.mainVC
            window.makeKeyAndVisible()
            window.alpha = 0
            UIView.animate(withDuration: 0.6) {
                window.alpha = 1
            }
        }
    }
}
