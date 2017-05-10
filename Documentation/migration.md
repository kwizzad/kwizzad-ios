# Migration guide from versions < `2.x.x`

- [Changelog](#changelog)
- [Step by step guide](#guide-step-by-step)
- [User experience](#user-experience--requesting-and-presenting-ads)
---

## Changelog
With version 2.0.0, we overhauled Kwizzad's SDK, cleaned up some API endpoints and added many new features.

If you used to integrate Kwizzad SDK in a version prior to `2.x.x`, there are some necessary and some optional changes:

- Necessary changes:
    - Prior versions used the Observable/Signal pattern for handling events. We simplified this with a [delegate pattern](https://developer.apple.com/library/content/documentation/Swift/Conceptual/BuildingCocoaApps/AdoptingCocoaDesignPatterns.html). This means that you have to adapt the [`KwizzadSDKDelegate`](/KwizzadSDK/KwizzadSDKDelegate.swift) protocol in the code that presents Kwizzad ads.
- New features:
    - The 'ad ready' callback is now called with more detailled reward information, as well as a string building toolkit for incentivizing strings like `Earn 2000 coins by playing a quiz`. See `incentiveTextForRewards` in [`Reward.swift`](./KwizzadSDK/model/Reward.swift) and the new example app to learn how to use this.
    - Your code now gets full campaign metadata to customize the ad button: a campaign image, headline, teaser text, and a brand name. Have a look at the example app t learn how your app can make use of this.
    - The new example app provides a styled, layouted ad button that you can copy into your app code (fully customizable)

---

## Guide Step by step
### step 1 : Initializing the SDK
  - with swift
    ```Swift
    // KwizzadSDK < 2
    KwizzadSDK.instance.configure(
      Configuration.create()
      .apiKey("YOUR_API_TOKEN_HERE")
      .build()
    )

    // KwizzadSDK 2
     KwizzadSDK.setup(apiKey: "YOUR_API_TOKEN_HERE"")```
  - with objective-c
     ```objc
     // KwizzadSDK < 2
     [KwizzadSDK.instance configure:[[KwizzadConfiguration alloc]
      initWithApiKey:@"YOUR_API_KEY_HERE"
      debug:YES]];

     // KwizzadSDK 2
     [KwizzadSDK setupWithApiKey:@"YOUR_API_TOKEN_HERE"];
     ```
### step 2 : Assigning Kwizzad Delegate protocol
  - with swift
    ```swift
    // KwizzadSDK 2
    import KwizzadSDK
    class ViewController: UIViewController, KwizzadSDKDelegate {
       override func viewDidLoad() {
          KwizzadSDK.instance.delegate = self
        }
    }
    ```
  - with objective-c
     ```objc
     // KwizzadSDK 2
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

```swift    
// KwizzadSDK < 2

 using the Observable/Signal pattern

// KwizzadSDK 2

 using the delegate pattern

    Mandatory callbacks :

    - kwizzadDidRequestAd:placementId
    - kwizzadOnAdAvailable:placementId:potentialRewards:adResponse
    - kwizzadOnAdReady:placementId
    - kwizzadDidShowAd:placementId
    - kwizzadGotOpenTransactions:placementId
    - kwizzadDidDismissAd:placementId
    - kwizzadOnNoFill:placementId

    Optionals Callbacks :

    - kwizzadOnErrorOccured:placementId:reason
    - kwizzadWillPresentAd:placementId
    - kwizzadOnGoalReached:placementId
    - kwizzadCallToActionClicked:placementId
```

---

## User experience : requesting and presenting ads

We recommend you request an ad from Kwizzad right when the view you want to display it in has
finished loading.

When an ad is available, you get a callback from the SDK with a method to actually show the ad,
and with potential rewards that your users can earn by playing the ad.

You can incentivize your users to open the ad with this potential reward information (for example
with a button: 'Click here to earn up to 10,000 coins!'). The SDK provides you a with a button
caption you can use.

If you want to customize the look & feel of the UI element that opens an ad (for example with a
custom animation), the SDK also provides your app with all necessary information (reward
amount, maximal amount, currencies and reward type—users can get rewards for different steps of
the campaign experience).

When your users dismiss ads, you get an information about if/how the user got pending transactions
for rewards. You can then display this information to your user—either summarized or with a dialog
for each single pending reward. As soon as your app confirms a transaction, its reward will be paid
out.

Transactions work like an inbox, so you might get transactions again (asynchronously) until your app
confirms them. Each transaction has an ID so you can keep a record of the rewards that you displayed
already.
