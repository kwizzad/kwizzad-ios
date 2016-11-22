Pod::Spec.new do |spec|
  spec.name = "KwizzadSDK"
  spec.version = "0.0.1"
  spec.summary = "Kwizzzzzzz"
  spec.homepage = "http://kwizzad.com/"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Sandro Manke" => 'sm@blitzentwickler.de' }
  spec.social_media_url = "http://kwizzad.com"

  spec.platform = :ios, "10.0"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/kwizzad/kwizzad-sdk-swift.git", tag: "v#{spec.version}", submodules: true }
  spec.source_files = "KwizzadSDK/**/*.{h,swift}"

  spec.dependency "Curry", "~> 2.3.3"
  spec.dependency "RxSwift", "~> 3.0.0.beta1"
  spec.dependency "RxCocoa", "~> 3.0.0.beta1"
  spec.dependency "Alamofire", "~> 4.0"
  spec.dependency "ObjectMapper", "~> 1.3"
  spec.dependency "SugarRecord/CoreData"
  spec.dependency "SwiftyJSON"
end
