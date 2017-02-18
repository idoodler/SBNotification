# SBNotification
Simple Statusbar Notification written in Swift.

It allows you to display notifications right on the StatusBar. Tap handlers are also supported!

Import SBNotification and you are good to go!

Example:

```swift
import SBNotification

// This toggles a red notification without any tap handler
SBNotificationManager.showNotification("Awesome Notification", duration: 20, type: .error)
```
