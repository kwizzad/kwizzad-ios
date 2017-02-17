//
//  ViewController.m
//  KwizzadExample
//
//  Created by Anatol Ulrich on 14/10/2016.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

#import "ObjCViewController.h"

#import <KwizzadSDK/KwizzadSDK-Swift.h>

@interface ObjCViewController () {
    BOOL running;
}

@property(nonatomic) IBOutlet UITextField *placementIdField;
@property(retain) UIViewController *kwizzadViewController;
@property(retain) NSObject *adSignal;
@property(retain) NSObject *transactionsSignal;

@end

@implementation ObjCViewController
@synthesize kwizzadViewController;
@synthesize adSignal;
@synthesize transactionsSignal;

- (void) viewDidLoad {
    [super viewDidLoad];

    NSString *placementId = nil;

    placementId = @"tvsa";

    self.placementIdField.text = placementId;
}

// Customize this to change how your app shows users their rewards.
// Note that each open transaction must be confirmed by the app (using `completeTransaction`).
// Unconfirmed transactions are shown again until they are confirmed.

- (void) handleTransaction:(KwizzadOpenTransaction *)transaction {
    NSLog(@"received %@, confirming", transaction);
    KwizzadReward *reward = transaction.reward;
    NSString *message = [NSString stringWithFormat:@"You've earned %@.", [reward asFormattedString]];
    if (reward) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle: @"Congratulations!"
                                                                       message: message
                                                                preferredStyle: UIAlertControllerStyleAlert];

        [alert addAction: [UIAlertAction actionWithTitle:@"Yo" style: UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [KwizzadSDK.instance completeTransaction:transaction];
        }]];

        [self presentViewController:alert animated:YES completion:nil];
    }
    else {
        // Silently confirm the transaction
        [KwizzadSDK.instance completeTransaction:transaction];
    }
}

- (IBAction)onStartButton {
    if (running) return;
    NSString *placementId = self.placementIdField.text;

    if (placementId.length == 0) return;

    running = YES;

    // For better targeting, you can set known user data here:
    KwizzadUserDataModel *userData = KwizzadSDK.instance.userDataModel;
    userData.userName = @"Francesca Rossi"; // user name inside your app
    userData.facebookUserId = @"1234abc";
    userData.userId = @"12345"; // identifies the user inside your app
    userData.gender = KwizzadGenderFemale;

    /**
     if you need to close the kwizzad, you have to call following:

     [KwizzadSDK.instance closeWithPlacementId:placementId]

     this will clean up everything.
     failing to do so will result in a memory leak.
     requestAdWithPlacementId:placementId];
     */
    [KwizzadSDK.instance requestAd:placementId];

    /* When the signal gets released, the callback is released too,
       so ensure it stays retained while the ad is running. */
    self.adSignal = [[KwizzadSDK.instance placementModel:placementId]
                adStateSignal:^(enum KwizzadAdState adState) {
                    switch (adState) {
                        case KwizzadAdStateINITIAL:
                            NSLog(@">> ad state INITIAL");
                            break;

                        case KwizzadAdStateRECEIVED_AD: {
                            NSDictionary* myCustomParameters = [NSDictionary dictionaryWithObjectsAndKeys:userData.userId, @"userId", nil];
                            self.kwizzadViewController = [KwizzadSDK.instance prepare:placementId customParameters:myCustomParameters];
                            
                            /* Optionally, you can use this to show the user their potential reward(s). */
                            KwizzadAdResponseEvent *adResponse = [KwizzadSDK.instance placementModel:placementId].adResponse;
                            NSMutableArray *rewardStrings = [NSMutableArray array];
                            for (KwizzadReward *reward in adResponse.rewards) {
                                [rewardStrings addObject:reward.asDebugString];
                                NSLog(@"Potential reward currency: %@", reward.currency);
                                NSLog(@"Potential reward amount: %@", reward.amount);
                                NSLog(@"Potential reward type: %@", reward.type);
                            }
                            NSString *rewardsString = [rewardStrings componentsJoinedByString:@", "];
                            NSLog(@"Potential rewards: %@", rewardsString);
                        }
                            break;

                        case KwizzadAdStateAD_READY:
                        {
                            [self presentViewController:self.kwizzadViewController animated:true completion:nil];
                        }
                            break;

                        case KwizzadAdStateDISMISSED:
                        {
                            self.adSignal = nil;
                            running = NO;

                            self.transactionsSignal = [KwizzadSDK.instance subscribeToPendingTransactionsWithCallback:^(NSSet<KwizzadOpenTransaction *> * _Nonnull transactions) {

                                KwizzadOpenTransaction *transaction = [transactions anyObject];

                                if (transaction) {
                                    [self handleTransaction:transaction];
                                }
                            }];
                        }
                            break;

                        case KwizzadAdStateNOFILL: {
                            self.adSignal = nil;
                            running = NO;
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                                           message:@"No ad available on this placement."
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                            [self presentViewController:alert animated:YES completion:nil];

                            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                [alert dismissViewControllerAnimated:true completion:nil];
                            }]];
                        }
                            break;

                        default:
                            break;
                    }
                }];
}


@end
