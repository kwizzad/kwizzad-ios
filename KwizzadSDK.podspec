Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '9.0'
s.name = "KwizzadSDK"
s.summary = "KWIZZAD is a native advertising platform that can be easily integrated into any mobile or web application in order to guarantee maximum flexibility in the monetization of your product."
s.requires_arc = true

#s.social_media_url = "http://kwizzad.com"

# 2
s.version = "0.7.7"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Kwizzad Team" => "info@kwizzad.com" }

# 5 - Replace this URL with your own Github page's URL (from the address bar)
s.homepage = "https://www.kwizzad.com"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/kwizzad/kwizzad-ios.git", :tag => "#{s.version}"}

# 7
s.frameworks   = ['Foundation', 'UIKit']



# 8

s.source_files = 'KwizzadSDK/*.{swift,h,m}'

# 9
s.resources = "KwizzadSDK/**/*.{png}"


s.dependency 'RxSwift', '~> 3.0'
s.dependency 'XCGLogger', '~> 4.0.0'


end
