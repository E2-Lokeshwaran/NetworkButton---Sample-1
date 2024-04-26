//
//  ViewController.swift
//  NetworkButton
//
//  Created by Lokeshwaran on 26/04/24.
//

import UIKit
import SystemConfiguration

class ViewController: UIViewController 
{
    
    @IBOutlet weak var img: UIImageView!
    
    
    var reachability: SCNetworkReachability?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            setupReachability()
            updateImageDisplay(isConnected: isConnectedToNetwork())
        }
        
        func setupReachability() {
            var zeroAddress = sockaddr_in()
            zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
            zeroAddress.sin_family = sa_family_t(AF_INET)
            
            guard let reachabilityRef = withUnsafePointer(to: &zeroAddress, {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    SCNetworkReachabilityCreateWithAddress(nil, $0)
                }
            }) else {
                return
            }
            
            reachability = reachabilityRef
            
            var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
            context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            
            let callbackEnabled: SCNetworkReachabilityCallBack? = { (reachability, flags, info) in
                let viewController = Unmanaged<ViewController>.fromOpaque(info!).takeUnretainedValue()
                viewController.handleReachabilityChanged(flags: flags)
            }
            
            SCNetworkReachabilitySetCallback(reachability!, callbackEnabled, &context)
            
            SCNetworkReachabilityScheduleWithRunLoop(reachability!, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        }
        
        func handleReachabilityChanged(flags: SCNetworkReachabilityFlags) {
            let isReachable = flags.contains(.reachable)
            let needsConnection = flags.contains(.connectionRequired)
            
            DispatchQueue.main.async {
                self.updateImageDisplay(isConnected: isReachable && !needsConnection)
            }
        }
        
        func updateImageDisplay(isConnected: Bool) {
            if isConnected {
                img.image = UIImage(named: "online")
            } else {
                img.image = UIImage(named: "offlin")
                showOfflineAlert()
            }
        }
        
        func showOfflineAlert() {
            let alert = UIAlertController(title: "No Internet Connection", message: "Please check your internet connection and try again.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
        
        func isConnectedToNetwork() -> Bool {
            var zeroAddress = sockaddr_in()
            zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
            zeroAddress.sin_family = sa_family_t(AF_INET)
            
            guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    SCNetworkReachabilityCreateWithAddress(nil, $0)
                }
            }) else {
                return false
            }
            
            var flags: SCNetworkReachabilityFlags = []
            if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
                return false
            }
            
            let isReachable = flags.contains(.reachable)
            let needsConnection = flags.contains(.connectionRequired)
            
            return (isReachable && !needsConnection)
        }
        
        deinit {
            SCNetworkReachabilitySetCallback(reachability!, nil, nil)
        }
    }
