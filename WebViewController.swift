import UIKit
import WebKit

class WebViewController: UIViewController {
    private var webView: WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = URL(string: "https://zhucan.xyz") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
} 
