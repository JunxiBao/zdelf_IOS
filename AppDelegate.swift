import UIKit
import AudioToolbox
import AVFoundation

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

        guard let path = Bundle.main.path(forResource: "intro", ofType:"mov") else {
            print("Video not found")
            return
        }
        let player = AVPlayer(url: URL(fileURLWithPath: path))
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        playerLayer.position = view.center
        playerLayer.backgroundColor = UIColor.clear.cgColor
        playerLayer.videoGravity = .resizeAspect
        playerLayer.opacity = 0
        view.layer.addSublayer(playerLayer)
        player.play()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.8)
            playerLayer.opacity = 1
            CATransaction.commit()
        }

        // 添加播放结束通知监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidFinishPlaying(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )

        // 提前加载主控制器视图
        _ = mainVC.view
    }

    @objc func videoDidFinishPlaying(_ notification: Notification) {
        if let blurView = view.subviews.compactMap({ $0 as? UIVisualEffectView }).first {
            transitionToMainScreen(blurView: blurView)
        } else {
            transitionToMainScreen(blurView: UIVisualEffectView(effect: nil))
        }
    }

    func transitionToMainScreen(blurView: UIVisualEffectView) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return }

        UIView.animate(withDuration: 0.6, animations: {
            self.view.alpha = 0
            blurView.alpha = 0
        }) { _ in
            window.rootViewController = self.mainVC
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            window.makeKeyAndVisible()

            window.alpha = 0
            UIView.animate(withDuration: 0.6) {
                window.alpha = 1
            }
        }
    }
}
