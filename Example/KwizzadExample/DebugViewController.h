//
//  DebugViewController.h
//  KwizzadExample
//
//  Created by Fares Ben Hamouda on 27.04.17.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KwizzadSDK/KwizzadSDK-Swift.h>
#import "KwizzadExampleObjc-Swift.h"

@interface DebugViewController : UIViewController<KwizzadSDKDelegate,UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *placementField;
@property (strong, nonatomic) IBOutlet UITextView *debugMessage;
@property (strong, nonatomic) IBOutlet AdView *adView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *height;
@property (strong, nonatomic) IBOutlet UIButton *preloadButton;

@property(retain) UIViewController *kwizzadViewController;

@end
