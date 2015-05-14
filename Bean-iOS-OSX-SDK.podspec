
Pod::Spec.new do |s|

  s.name         = "Bean-iOS-OSX-SDK"
  s.version      = "0.9.0"
  s.summary      = "Punch Through Design's SDK for speeding up development with the LightBlue Bean development platform"
  s.homepage     = "https://github.com/PunchThrough/Bean-iOS-OSX-SDK"
  s.license      = { :type => "MIT", :file => "LICENSE.txt" }
  
  s.author             = { "Punch Through Design" => "info@punchthrough.com" }
  s.documentation_url = 'http://punchthrough.com/files/bean/sdk-docs/index.html'

  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.9"

  s.source       = { :git => "https://github.com/PunchThrough/Bean-iOS-OSX-SDK.git", :tag => "0.9.0", :submodules => true }

  s.source_files  = "App Message Definitions/*.{h,m}","Bean OSX Static Library/**/*.{h,m}","source","source/**/*.{h,m}"
  s.exclude_files = "Bean OSX Static Library/Bean OSX LibraryTests/**/*.{h,m}"
  s.resource = "firmware/*"

  s.ios.frameworks = "CoreBluetooth"
  s.osx.frameworks = "IOBluetooth"

  s.requires_arc = true
  s.prefix_header_contents = '#import "BEAN_Globals.h"'

  s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SRCROOT)/../bean-apple-sdk/source/Public" }

end

