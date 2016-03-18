# LightBlue Bean SDK for iOS and OS X

Punch Through Design's SDK for speeding up development with the [LightBlue Bean](https://punchthrough.com/bean) development platform. Build iOS and OS X apps that talk to your Beans.

To get started with the SDK, check out our installation instructions below, then read our [Reference Docs](http://punchthrough.com/files/bean/sdk-docs/index.html).

# Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C which automates and simplifies the process of using third-party libraries. If you're new to CocoaPods, check out the [Getting Started](https://guides.cocoapods.org/using/getting-started.html) and [Using CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html) guides.

Add the following to your Podfile, then run `pod install`:

## Podfile for iOS

```ruby
platform :ios
pod 'Bean-iOS-OSX-SDK'
```

## Podfile for OS X

```ruby
platform :osx
pod 'Bean-iOS-OSX-SDK'
```

# Installation from Source

You can clone the SDK to add it to your project without using CocoaPods. Since this project uses Git submodules, you will have to clone and pull with them in mind.

## Clone the Repo

```
git clone REPO_URL --recursive
```

## Update to Latest Release

```
git pull
git submodule sync
git submodule update --recursive
```

# Attribution

If you use our SDK to build something cool, we'd appreciate it if you did the following:

 * Link to the Bean page ([https://punchthrough.com/bean/](https://punchthrough.com/bean/)). This could be your readme file, your website's footer, your app's About page, or anywhere you think your users will see it. We appreciate these links because they help people discover Bean.
 * Let us know what you've built! Our favorite part at Punch Through is when people tell us about projects they're building and what they've accomplished with our products. You could post on [Beantalk, our community forum](http://beantalk.punchthrough.com/), post on [Hackster.io, our project space](https://www.hackster.io/punchthrough), mention us on [Twitter at @PunchThrough](http://twitter.com/punchthrough), or email us at [info@punchthrough.com](mailto:info@punchthrough.com).

# License

This SDK is covered under **The MIT License**. See `LICENSE.txt` for more details.
