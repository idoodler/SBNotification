# SBNotification
Simple Statusbar Notification written in Swift.

![alt tag](https://www.idoodler.de/resources/SBNotification.gif)

It allows you to display notifications right on the StatusBar. Tap handlers are also supported!

Either import the ready framework or drag `SBNotification.xcodeproj` into your project to reference it.
Then import SBNotification

Example:

```swift
import SBNotification

// This toggles a red notification without any tap handler
SBNotificationManager.showNotification("Awesome Notification", duration: 20, type: .error)
```
