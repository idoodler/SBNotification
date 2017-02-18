//
//  StatusBarNotificationManager.swift
//  StatusBarNotification
//
//  Created by David Gölzhäuser on 11.02.17.
//  Copyright © 2017 David Gölzhäuser. All rights reserved.
//

import Foundation
import UIKit

public enum NotificationType {
    case error, warning, success, info, debug, server
}

public class SBNotificationManager {
    
    fileprivate static let sharedInstance = SBNotificationManager()
    
    fileprivate var notificationQueue: [SBNotification] = []
    fileprivate var staticNotification : SBNotification?
    fileprivate var notificationHistory: [SBNotification] = []
    
    public class func showNotification(_ title: String!, duration: TimeInterval, animationDuration: TimeInterval = 0.25, type: NotificationType, completion: (() -> Void)!, clickHandler: (() -> Void)! = nil) {
        guard Thread.current.isMainThread else {
            print("Only from Mainthread!")
            return
        }
        
        let notif = SBNotification(title: title, duration: duration, type: type, completion: { (notification) -> Void in
            if (completion != nil) {
                completion()
            }
            self.sharedInstance.dequeuNotificationAndShowNextInQueue(notification)
        }, clickHandler: { (notification) -> Void in
            if (clickHandler != nil) {
                clickHandler()
            }
            notification.dismiss()
        }, animationDuration: animationDuration)
        self.sharedInstance.queueNotificationAndShow(notif)
        
    }
    
    public class func showStaticNotification(_ title: String!, type: NotificationType, animationDuration: TimeInterval = 0.25, completion: (() -> Void)!, clickHandler: (() -> Void)! = nil) {
        guard Thread.current.isMainThread else {
            print("Only from Mainthread!")
            return
        }
        
        guard (self.sharedInstance.staticNotification == nil) else {
            print("Only one static notification is allowed.")
            return
        }
        
        let notif = SBNotification(title: title, duration: -1.0, type: type, completion: { (notification) -> Void in
            if (completion != nil) {
                completion()
            }
        }, clickHandler: { (notification) -> Void in
            if (clickHandler != nil) {
                clickHandler()
            }
        }, animationDuration: animationDuration)
        self.sharedInstance.staticNotification = notif
        self.sharedInstance.showStaticNotification()
    }
    
    public class func getNotificationHistoryViews() -> [UIView] {
        var views: [UIView] = []
        for notification in self.sharedInstance.notificationHistory {
            views.append(notification.notificationView)
        }
        return views
    }
    
    public class func clearAllQueuedNotifications() {
        if let notification = self.sharedInstance.notificationQueue.first {
            notification.dismiss()
        }
        self.sharedInstance.notificationQueue.removeAll()
    }
    
    public class func dismissStaticNotification() {
        if let notif = self.sharedInstance.staticNotification {
            notif.dismiss()
            self.sharedInstance.staticNotification = nil
        } else {
            print("There is no static notification!")
        }
    }
    
    fileprivate func queueNotificationAndShow(_ notification: SBNotification) {
        notificationQueue.append(notification)
        notificationHistory.append(notification)
        if notificationQueue.count == 1 {
            hideStaticNotification()
            notification.show()
        }
    }
    
    fileprivate func dequeuNotificationAndShowNextInQueue(_ notification: SBNotification) {
        if notificationQueue.contains(notification) {
            notificationQueue.remove(at: self.notificationQueue.index(of: notification)!)
        }
        if notificationQueue.count > 0 {
            notificationQueue.first?.show()
        } else {
            showStaticNotification()
        }
    }
    
    fileprivate func hideStaticNotification() {
        if let notif = staticNotification {
            notif.dismiss()
        } else {
            print("There is no static notification!")
        }
    }
    
    fileprivate func showStaticNotification() {
        if notificationQueue.isEmpty {
            if let notif = staticNotification {
                notif.show()
            } else {
                print("There is no static notification!")
            }
        }
    }
}

fileprivate extension UIApplication {
    var statusBarView: UIView? {
        return value(forKey: "statusBar") as? UIView
    }
}

private class SBNotification: NSObject {
    
    let notificationView: UIView!
    let notificationUUID = UUID().uuidString
    
    fileprivate let completion: ((_ notification: SBNotification) -> Void)!
    fileprivate let clickHandler: ((_ notification: SBNotification) -> Void)!
    fileprivate var statusBar: UIView?
    fileprivate var statusBarFrame: CGRect!
    fileprivate let duration: TimeInterval!
    fileprivate let label: UILabel!
    fileprivate let animationDuration: TimeInterval!
    fileprivate var timer: Timer! = nil
    
    init(title: String!, duration: TimeInterval, type: NotificationType, completion: ((_ notification: SBNotification) -> Void)!, clickHandler: ((_ notification: SBNotification) -> Void)!, animationDuration: TimeInterval) {
        self.completion = completion
        self.clickHandler = clickHandler
        if let sb = UIApplication.shared.statusBarView {
            self.statusBar = sb
            self.statusBarFrame = self.statusBar!.frame
        } else {
            self.statusBar = nil
            self.statusBarFrame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: 20.0)
        }
        
        var notificationFrame = self.statusBarFrame
        notificationFrame?.origin.y = -(notificationFrame?.size.height)!
        self.notificationView = UIView(frame: notificationFrame!)
        self.label = UILabel(frame: CGRect(origin: CGPoint(x: 2, y: 0), size: CGSize(width: (notificationFrame?.size.width)! - 4, height: (notificationFrame?.size.height)!)))
        
        self.notificationView.addSubview(self.label);
        self.notificationView.window?.windowLevel = UIWindowLevelStatusBar * 1000
        self.notificationView.bringSubview(toFront: self.label)
        self.label.font = UIFont.systemFont(ofSize: 13)
        self.label.textAlignment = .center
        self.duration = duration
        self.animationDuration = animationDuration
        
        switch type {
        case .error:
            self.notificationView.backgroundColor = UIColor(red: 0.937, green: 0.161, blue: 0.137, alpha: 1.000)
            self.label.textColor = .white; self.label.text = title
        case .warning:
            self.notificationView.backgroundColor = UIColor(red: 0.969, green: 0.412, blue: 0.145, alpha: 1.000)
            self.label.textColor = .white; self.label.text = title
        case .success:
            self.notificationView.backgroundColor = UIColor(red: 0.224, green: 0.792, blue: 0.455, alpha: 1.000)
            self.label.textColor = .white; self.label.text = title
        case .info:
            self.notificationView.backgroundColor = .lightGray
            self.label.textColor = .white; self.label.text = title
        case .debug:
            self.notificationView.backgroundColor = .black
            self.label.textColor = .green; self.label.text = "🔨 " + title
        case .server:
            self.notificationView.backgroundColor = UIColor(red: 0.271, green: 0.522, blue: 0.831, alpha: 1.000);
            self.label.textColor = .white; self.label.text = title
        }
    }
    
    @objc func show() {
        NotificationCenter.default.addObserver(self, selector: #selector(SBNotification.adjustSize), name: NSNotification.Name.UIApplicationDidChangeStatusBarFrame, object: nil)
        self.notificationView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SBNotification.clickedOnNotification)))
        adjustSize()
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.keyWindow?.addSubview(self.notificationView)
            UIApplication.shared.keyWindow?.bringSubview(toFront: self.notificationView)
            self.showViewWithAnimation(self.notificationView) { (finished) -> Void in
                if (self.duration > 0) {
                    self.timer = Timer.scheduledTimer(timeInterval: self.duration, target: self, selector: #selector(SBNotification.dismiss), userInfo: nil, repeats: false)
                }
            }
            self.hideViewWithAnimation(self.statusBar!, comp: nil)
        })
    }
    
    @objc func dismiss() {
        NotificationCenter.default.removeObserver(self)
        DispatchQueue.main.async(execute: { () -> Void in
            self.hideViewWithAnimation(self.notificationView) { (finished) -> Void in
                self.completion?(self)
                self.notificationView.removeFromSuperview()
            }
            self.showViewWithAnimation(self.statusBar!, comp: nil)
        })
    }
    
    fileprivate func showViewWithAnimation(_ view: UIView, comp: ((_ finished: Bool) -> Void)?) {
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            view.frame.origin.y = 0
        }, completion: comp)
    }
    
    fileprivate func hideViewWithAnimation(_ view: UIView, comp: ((_ finished: Bool) -> Void)?) {
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            view.frame.origin.y = -self.statusBarFrame.size.height
        }, completion: comp)
    }
    
    @objc fileprivate func adjustSize() {
        notificationView.frame.size = statusBarFrame.size
        label.frame = CGRect(origin: CGPoint(x: 2, y: 0), size: CGSize(width: statusBarFrame.size.width - 4, height: statusBarFrame.size.height))
    }
    
    @objc fileprivate func clickedOnNotification() {
        if (self.timer != nil) {
            self.timer.invalidate()
            self.timer = nil
        }
        clickHandler?(self)
    }
}
