Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '8.0'
s.name = "KwizzadSDK"
s.summary = "KWIZZAD is the new advertising format for gamified, native advertising"
s.description = "KWIZZAD is the new advertising format for gamified, native advertising.
With KWIZZAD, we are redefining digital advertising by offering both advertisers and publishers the opportunity to meet their goals better than ever before. "
s.requires_arc = true
#s.social_media_url = "http://kwizzad.com"

# 2
s.version = "0.7.9"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Kwizzad Team" => "info@kwizzad.com" }

# 5 - Replace this URL with your own Github page's URL (from the address bar)
s.homepage = "https://github.com/kwizzad/kwizzad-ios"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/kwizzad/kwizzad-ios.git", :tag => "#{s.version}"}

# 7
s.frameworks   = ['Foundation', 'UIKit']

# 8 - Source files
s.source_files = "KwizzadSDK/**/*.{swift,h,m}"

# 9 - Resources
s.resources = ["KwizzadSDK/**/*.{strings}" , "KwizzadSDK/**/**/*.{png,json}"]

# 10 - Dependencies
s.dependency 'RxSwift', '~> 3.0'
s.dependency 'XCGLogger', '~> 4.0.0'


end
