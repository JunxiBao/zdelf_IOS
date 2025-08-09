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

    // State for animation and selection
    private var didVideoFinish = false
    private var isChoosingAppearance = false
    private weak var pendingBlurView: UIVisualEffectView?

    // Appearance storage and modes
    private let appearanceKey = "AppearanceOption"
    private enum AppearanceOption: Int {
        case followSystem = 0
        case light = 1
        case dark = 2
    }

    private var currentAppearance: AppearanceOption {
        get {
            let raw = UserDefaults.standard.integer(forKey: appearanceKey)
            return AppearanceOption(rawValue: raw) ?? .followSystem
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: appearanceKey)
            applyAppearance(newValue)
        }
    }

    private lazy var gearButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.image = UIImage(systemName: "circle.lefthalf.filled")
            config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            button.configuration = config
        } else {
            button.setImage(UIImage(systemName: "circle.lefthalf.filled"), for: .normal)
        }
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        button.layer.cornerRadius = 16
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        button.accessibilityLabel = "设置"
        button.addTarget(self, action: #selector(showAppearanceSheet), for: .touchUpInside)
        return button
    }()

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

        // 设置按钮（右下角齿轮）
        view.addSubview(gearButton)
        gearButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gearButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            gearButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        // 应用已保存的外观偏好
        applyAppearance(currentAppearance)

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
        didVideoFinish = true
        if let blurView = view.subviews.compactMap({ $0 as? UIVisualEffectView }).first {
            if isChoosingAppearance {
                pendingBlurView = blurView
                return
            }
            transitionToMainScreen(blurView: blurView)
        } else {
            if isChoosingAppearance {
                pendingBlurView = UIVisualEffectView(effect: nil)
                return
            }
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
            // 在切换前应用外观到主界面
            let styleToApply: UIUserInterfaceStyle = {
                switch self.currentAppearance {
                case .followSystem: return .unspecified
                case .light: return .light
                case .dark: return .dark
                }
            }()
            self.mainVC.overrideUserInterfaceStyle = styleToApply
            window.overrideUserInterfaceStyle = styleToApply

            window.rootViewController = self.mainVC
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            window.makeKeyAndVisible()

            window.alpha = 0
            UIView.animate(withDuration: 0.6) {
                window.alpha = 1
            }
        }
    }

    @objc private func showAppearanceSheet() {
        isChoosingAppearance = true
        let sheet = UIAlertController(title: "外观", message: "选择网页外观模式", preferredStyle: .actionSheet)

        let follow = UIAlertAction(title: "跟随系统", style: .default) { _ in
            self.currentAppearance = .followSystem
            self.finishChoosing()
        }
        let light = UIAlertAction(title: "浅色", style: .default) { _ in
            self.currentAppearance = .light
            self.finishChoosing()
        }
        let dark = UIAlertAction(title: "深色", style: .default) { _ in
            self.currentAppearance = .dark
            self.finishChoosing()
        }
        let cancel = UIAlertAction(title: "取消", style: .cancel) { _ in
            self.finishChoosing()
        }

        sheet.addAction(follow)
        sheet.addAction(light)
        sheet.addAction(dark)
        sheet.addAction(cancel)

        // iPad 弹出锚点
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = gearButton
            pop.sourceRect = gearButton.bounds
        }

        present(sheet, animated: true)
    }

    private func applyAppearance(_ option: AppearanceOption) {
        let style: UIUserInterfaceStyle
        switch option {
        case .followSystem:
            style = .unspecified
        case .light:
            style = .light
        case .dark:
            style = .dark
        }

        // 影响启动页自身
        view.window?.overrideUserInterfaceStyle = style
        self.overrideUserInterfaceStyle = style

        // 影响主 WebView 控制器（如果站点支持 prefers-color-scheme 会跟随）
        mainVC.viewIfLoaded?.overrideUserInterfaceStyle = style
    }

    // 结束外观选择后，如果视频已结束则继续跳转
    private func finishChoosing() {
        isChoosingAppearance = false
        if didVideoFinish {
            let blur = pendingBlurView ?? view.subviews.compactMap({ $0 as? UIVisualEffectView }).first ?? UIVisualEffectView(effect: nil)
            pendingBlurView = nil
            transitionToMainScreen(blurView: blur)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
