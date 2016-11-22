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
    BOOL started;
    UIViewController *kwizzadViewController;
    NSObject *adSignal;
    NSObject *transactionsSignal;
}

@property(nonatomic, weak) IBOutlet UITextField *placementIdField;

@end

@implementation ObjCViewController

-(void) viewDidLoad {
    [super viewDidLoad];
    
    NSString *placementId = nil;
    
    placementId = @"tvsa";
    
    self.placementIdField.text = placementId;
    
}

-(IBAction)onStartButton {
    if (started) return;
    NSString *placementId = self.placementIdField.text;
    
    if (placementId.length == 0) return;
    
    started = YES;
    
    
    /**
     if you need to close the kwizzad, you have to call following:
     
     [KwizzadSDK.instance closeWithPlacementId:placementId]
     
     this will clean up everything.
     failing to do so will result in a memory leak.
     requestAdWithPlacementId:placementId];
     */
    [KwizzadSDK.instance requestAd:placementId];
    
    
    adSignal = [[KwizzadSDK.instance placementModel:placementId]
                adStateSignal:^(enum KwizzadAdState adState) {
                    switch (adState) {
                        case KwizzadAdStateINITIAL:
                            NSLog(@">> ad state INITIAL");
                            break;
                        case KwizzadAdStateRECEIVED_AD: {
                            kwizzadViewController = [KwizzadSDK.instance prepare:placementId customParameters:nil];
                        }
                            
                            break;
                        case KwizzadAdStateAD_READY:
                        {
                            [self presentViewController:kwizzadViewController animated:true completion:nil];
                        }
                            break;
                            
                        case KwizzadAdStateDISMISSED:
                        {
                            
                            adSignal = nil;
                            started = NO;
                            
                            transactionsSignal = [KwizzadSDK.instance subscribeToPendingTransactionsWithCallback:^(NSSet<KwizzadOpenTransaction *> * _Nonnull transactions) {
                                
                                KwizzadOpenTransaction *transaction = [transactions anyObject];
                                
                                if (transaction) {
                                    NSLog(@"received %@, confirming", transaction);
                                    [KwizzadSDK.instance completeTransaction:transaction];
                                }
                            }];
                        }
                            break;
                            
                        default:
                            break;
                    }
                }];
}


@end
