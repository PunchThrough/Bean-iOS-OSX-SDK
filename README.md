# LightBlue Bean SDK for iOS & OSX

Punch Through Design's SDK for speeding up development with the LightBlue Bean development platform. Build iOS and OS X apps that talk to your Beans. To get started with the SDK, look below and check out our [Reference Docs](http://punchthrough.com/files/bean/sdk-docs/index.html).

# How to Clone and Pull from this repo

## Clone
		git clone REPO_URL --recursive

## Initialize Submodules 
####(This is unnecessary if the recursive clone works)
		git submodule update --init --recursive

## Pull
		git pull
		git submodule update --recursive

# Installation with CocoaPods 

[CocoaPods](http://cocoapods.org)  is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like the Bean-iOS-OSX-SDK. See the See the ["Getting Started" guide for more information](https://github.com/PunchThrough/Bean-iOS-OSX-SDK/wiki).

#### Podfile for iOS

```ruby
platform :ios, '7.0'
pod 'Bean-iOS-OSX-SDK', :git => "https://github.com/PunchThrough/Bean-iOS-OSX-SDK.git", :tag => '0.1.1', :submodules => true
```

#### Podfile for OSX

```ruby
platform :osx, '10.9' 
pod 'Bean-iOS-OSX-SDK', :git => "https://github.com/PunchThrough/Bean-iOS-OSX-SDK.git", :tag => '0.1.1', :submodules => true
```


# Attribution

If you use our SDK to build something cool, we'd appreciate it if you did the following:

 * Link to the Bean page ([http://punchthrough.com/bean/](http://punchthrough.com/bean/)). This could be your README.md file, your website's footer, your app's About page, or anywhere you think your users will see it. We appreciate these links because they help people discover the LightBlue Bean, and we want to everyone building something cool with the Bean.
 * Let us know what you've built! Our favorite part at Punch Through is when people tell us about projects they're building and what they've accomplished with our products. You could post on [Beantalk, our community forum](http://beantalk.punchthrough.com/), mention us on [Twitter @PunchThrough](http://twitter.com/punchthrough), or email us at [info@punchthrough.com](mailto:info@punchthrough.com).
 
# Licensing

This SDK is covered under **The MIT License**. See `LICENSE.txt` for more details.
