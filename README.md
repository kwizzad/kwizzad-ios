# Setting up the SDK build

- Checkout this repository with examples for Objective-C and Swift 3.
- Install [Homebrew](http://brew.sh/).
- Install carthage with `brew install carthage`. If you don’t want to use home-brew, download installer from [Carthage Homepage at GitHub](https://github.com/Carthage/Carthage)
- Run `/bin/setup` on the command line. This downloads and builds the SDK's dependencies.
- Open `KwizzadSDK.xcworkspace`.
- Run ExampleApp (Swift) or ExampleAppObjc (Objective-C) to see your first KWIZZAD


# How to integrate the SDK into your app

1. Put a Cartfile into your project
Contents of Cartfile:
```
github "kwizzad/kwizzad-ios" "master"
```

3. Run ```carthage checkout```
4. Look at the KwizzadExample app project. There are two build schemes, one for Swift, one for Objective-C.
5. Confirm everything works and you can get a KWIZZAD test campaign
6. Talk to your KWIZZAD publisher support team to receive your individual API keys and placement IDs


## with Swift

Test using the `KwizzadExample` target.

Initialize the SDK like this in your app delegate:

    KwizzadSDK.instance.configure(
      Configuration.create()
      .apiKey("YOUR_API_TOKEN_HERE")
      .build()
    )

`ViewController.swift` contains an exemplary integration of an ad placement in a view controller.

## with Objective-C

Test using the `KwizzadExampleObjc` target.

Initialize the SDK like this in your app delegate:

    [KwizzadSDK.instance configure:
      [[KwizzadConfiguration alloc]
        initWithApiKey:@"YOUR_API_KEY_HERE"
        debug:YES]
    ];

`ViewController.m` contains an exemplary integration of an ad placement in a view controller.