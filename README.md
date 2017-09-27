<img align="center" src="https://kwizzad.com/assets/kwizzad_logo-ea8ef9f88e2dd51829c0497740a4f190ad1821acdbec71bef32d47d458143549.svg" alt="" width="40" height="40"> Kwizzad SDK for iOS
====================


[![Pod version](https://img.shields.io/cocoapods/v/KwizzadSDK.svg)](https://cocoapods.org/pods/KwizzadSDK) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Github Release](https://img.shields.io/github/release/kwizzad/kwizzad-ios.svg)](https://github.com/kwizzad/kwizzad-ios/releases)

- [Showcase](#showcase)
- [Prerequisites](#prerequisites)
- [Migration](#migration)
- [Installation](#installation)
- [Usage](#usage)

## Showcase

![Showcase](https://github.com/kwizzad/kwizzad-ios/blob/master/Documentation/demo.gif)

## Prerequisites
- You already have your own KWIZZAD API KEY and PLACEMENT ID. If not, please contact TVSMILES per [E-Mail](mailto:it@tvsmiles.de) and we will register your APP.
- Apps integrating KWIZZAD SDK require at least iOS 8.0.
- A fully working examples (objective-c and swift) can be found at: [Examples](/KwizzadExample)

## Migration
Migration guide from versions < `2.x.x`

- [Migration guide](/Documentation/migration.md)

## Installation
How to integrate KwizzadSDK
Kwizzad supports Swift and ObjectiveC, and provides packages for [CocoaPods](http://cocoapods.org)
and [Carthage](https://github.com/Carthage/Carthage).


  #### Carthage

Carthage is a dependency manager for Cocoa. To install Carthage, please consult the
[documentation](https://github.com/Carthage/Carthage).

To load the Kwizzad SDK over Carthage:

- Put a `Cartfile` into your project. Contents:
  ```
  github "kwizzad/kwizzad-ios" "master"
  ```
  You can replace `master` by a specific version number you want to stick to, for example `2.0.0`.
- Run `carthage checkout`


  #### CocoaPods

[CocoaPods](http://cocoapods.org) is also a dependency manager for Cocoa projects.
You can install it with the following command:

```bash
$ gem install cocoapods
```

To load the Kwizzad SDK over CocoaPods:

- Integrate KwizzadSDK into your Xcode project using CocoaPods by specifying this in your `Podfile`:
  ```ruby
  source 'https://github.com/CocoaPods/Specs.git'
  use_frameworks!

  target '<Your Target Name>' do
      pod 'KwizzadSDK'
      # Alternatively, if you want to stick to a specific Kwizzad SDK version:
      # pod 'KwizzadSDK', '<version number goes here>'
  end
  ```
- Run the following command in your terminal, in the root directory of your project:
  ```bash
  $ pod install
  ```

## Usage:

### step 1 : Initializing the SDK

  - with swift
    ```Swift
     KwizzadSDK.setup(apiKey: "YOUR_API_TOKEN_HERE"")```

  - with objective-c
     ```objc
     [KwizzadSDK setupWithApiKey:@"YOUR_API_TOKEN_HERE"];
     ```

### step 2 : Assigning Kwizzad Delegate protocol

  - with swift
    ```swift
    import KwizzadSDK
    class ViewController: UIViewController, KwizzadSDKDelegate {
       override func viewDidLoad() {
          KwizzadSDK.instance.delegate = self
        }
    }
    ```

  - with objective-c
     ```objc
     @interface ViewController () <KwizzadSDKDelegate>
     @end

     @implementation ViewController
     - (void)viewDidLoad {
      KwizzadSDK.instance.delegate = self;
     }
    ```

### step 3 : Requesting Ad

  - with swift
      ```swift
      KwizzadSDK.instance.requestAd(placementId: YOUR_PLACEMENT)
      ```

  - with objective-c
       ```objc
       [KwizzadSDK.instance requestAdWithPlacementId:YOUR_PLACEMENT onAdAvailable:nil];
      ```

### step 4 : Implement the delegate functions

  Please have a look at the KwizzadExample app project. There are two build schemes, one for Swift, one for objective-c, to implement the delegate functions.

  - with swift
  [`DebugViewController.swift`](./KwizzadExample/KwizzadExample/DebugViewController.swift) contains an
  exemplary integration of an ad placement in a view controller.

  - with objective-c
  [`DebugViewController.m`](./KwizzadExample/KwizzadExample/DebugViewController.m) contains an exemplary integration of an ad placement in a view controller.

  For better targeting, please set your user data : 
  ```swift  
  let userData = kwizzad.userDataModel;
  userData.userId = "12345" 
  userData.gender = Gender.Female
  userData.userName = "Francesca Rossi" 
  userData.facebookUserId = "1234abc"
  ```



```swift    
 using the delegate pattern

    Mandatory callbacks :

    - kwizzadDidRequestAd:placementId
    - kwizzadOnAdAvailable:placementId:potentialRewards:adResponse
    - kwizzadOnAdReady:placementId
    - kwizzadDidShowAd:placementId
    - kwizzadGotOpenTransactions:openTransactions
    - kwizzadDidDismissAd:placementId
    - kwizzadOnNoFill:placementId

    Optionals Callbacks :

    - kwizzadOnErrorOccured:placementId:reason
    - kwizzadWillPresentAd:placementId
    - kwizzadOnGoalReached:placementId
    - kwizzadCallToActionClicked:placementId
```
