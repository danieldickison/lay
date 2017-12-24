//
//  ViewController.swift
//  Looking At You
//
//  Created by Daniel Dickison on 12/16/17.
//  Copyright © 2017 Daniel Dickison. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {
    
    let HOST = "http://10.0.1.10:3000"
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingImage: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        let req = URLRequest(url: URL(string: "\(HOST)/tablettes/index")!)
        webView.load(req)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("weview committed navigation \(navigation)")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webview finished navigation \(navigation)")
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn], animations: {
            self.loadingImage?.alpha = 0
        }, completion: {_ in
            self.loadingImage?.removeFromSuperview()
        })
    }
}
