//
//  DebugViewController.m
//  KwizzadExample
//
//  Created by Fares Ben Hamouda on 27.04.17.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

#import "DebugViewController.h"

@interface DebugViewController ()

@end

@implementation DebugViewController

KwizzadSDK* kwizzadInstance;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self clearLog];
}

-(void) viewDidAppear:(BOOL)animated {
    kwizzadInstance = KwizzadSDK.instance ;
    kwizzadInstance.delegate = self;
    [self preloadButtonPressed:self];
}

- (IBAction)preloadButtonPressed:(id)sender {
    // Fade adview while preloading ad
    _preloadButton.enabled = NO;
    _adView.alpha = 0.3;
    _adView.headlineLabel.text = @"Loading..." ;
    _adView.detailsLabel.text = @"Loading..." ;
    
    if ( [_placementField.text  isEqual: @""]) {
        return;
    } else {
        [kwizzadInstance requestAdWithPlacementId:_placementField.text onAdAvailable:nil];
        _kwizzadViewController = nil;
        [self clearLog];
        [_placementField resignFirstResponder];
    }
}

- (IBAction)enableAutomaticPreload:(UISwitch *)sender {
    kwizzadInstance.preloadAdsAutomatically = [sender isOn];
}

- (IBAction)startAd:(id)sender {
    if ( [kwizzadInstance canShowAdWithPlacementId:_placementField.text]) {
        [self presentViewController:_kwizzadViewController animated:YES completion:nil];
    }
}

-(void) loadImage:(NSString*)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData:data];
    [_adView.imageView setImage:image];
}

/////////////////////////////////////////////////////////////////////
//                                                                 //
//  The following delegate methods are called by the Kwizzad SDK.  //
//                                                                 //
/////////////////////////////////////////////////////////////////////

- (void) kwizzadDidRequestAdWithPlacementId:(NSString *)placementId {
    [self log:[NSString stringWithFormat:@"Requested an ad on placement %@",placementId]];
}

-(void) kwizzadOnAdAvailableWithPlacementId:(NSString *)placementId potentialRewards:(NSArray<KwizzadReward *> *)potentialRewards adResponse:(KwizzadAdResponseEvent *)adResponse {
    [self log:[NSString stringWithFormat:@"A new ad is available on placement %@",placementId]];
    [self.adView setHidden:NO];
    
    // For better targeting, you can set known user data here:
    KwizzadUserDataModel *userData = kwizzadInstance.userDataModel;
    userData.userName = @"Francesca Rossi"; // user name inside your app
    userData.facebookUserId = @"1234abc";
    userData.userId = @"12345"; // identifies the user inside your app
    userData.gender = KwizzadGenderFemale;
    
    NSDictionary<NSString * ,id> *customParameters = [[NSDictionary alloc]init] ;// Optionally, you can supply custom parameters for special use cases here.
    
    _kwizzadViewController = [kwizzadInstance loadAdWithPlacementId:placementId customParameters:customParameters];
    
    int thumbnailWidth = 400;
    NSString *thumbnailUrlString = [adResponse squaredThumbnailURLWithWidth:thumbnailWidth];

    [self loadImage:thumbnailUrlString];
    
    // If you want, you can also make use of the campaign's teaser text, headline and brand name.
    // All of these values are optional, so ensure your code works when they are `nil`.
    KwizzadAdMetaInfo *adMetaInfo = adResponse.adMetaInfo;
    [self log:[NSString stringWithFormat:@"Teaser for campaign's content: %@", adMetaInfo.teaser]];
    [self log:[NSString stringWithFormat:@"Brand name: %@", adMetaInfo.brand]];
    NSString *incentiveText = [KwizzadReward incentiveTextForRewards:potentialRewards];
    
    _adView.headlineLabel.text = adMetaInfo.headline;
    _adView.detailsLabel.text = incentiveText;
    
    if ( potentialRewards.count > 0) {
        [_adView.smilesLabel setHidden:NO];
        _adView.smilesLabel.text = [NSString stringWithFormat:@"+%@",[[KwizzadReward summarizeWithRewards:potentialRewards].firstObject valueOrMaxValue]];
    } else {
        [_adView.smilesLabel setHidden:YES];
    }
    
    [_adView layoutSubviews];
    self.height.constant = [_adView preferredHeight];
    [_adView layoutSubviews];
    
    // Optionally, you can use this to show the user their potential reward(s).
    [self log:[NSString stringWithFormat:@"Potential rewards: %@", [KwizzadReward enumerateRewardsAsTextWithRewards:potentialRewards]]];
}

- (void) kwizzadOnAdReadyWithPlacementId:(NSString *)placementId {
    [self log:[NSString stringWithFormat:@"The ad on placement %@ is loaded / ready to be displayed.",placementId]];
    _preloadButton.enabled = YES;
    _adView.alpha = 1.0;
}

- (void) kwizzadDidShowAdWithPlacementId:(NSString *)placementId {
    [self log:[NSString stringWithFormat:@"The ad on placement %@ is shown.",placementId]];
}

- (void) kwizzadDidDismissAdWithPlacementId:(NSString *)placementId {
    [self log:[NSString stringWithFormat:@"The ad on placement %@ has been dismissed.",placementId]];
}

- (void) kwizzadGotOpenTransactionsWithOpenTransactions:(NSSet<KwizzadOpenTransaction *> *)openTransactions{
    [self log:[NSString stringWithFormat:@"%lu incoming transactions to be confirmed.",(unsigned long)openTransactions.count]];
    
    
    NSMutableArray *rewards = [[NSMutableArray alloc]init];
    
    // Get rewards from openTransactions.
    [openTransactions enumerateObjectsUsingBlock:^(KwizzadOpenTransaction * _Nonnull transaction, BOOL * _Nonnull stop) {
        KwizzadReward* reward = transaction.reward;
        [rewards addObject:reward];
    }];
 
    [self log:[NSString stringWithFormat:@"Earned rewards: %@", [KwizzadReward enumerateRewardsAsTextWithRewards: rewards]]];

    if (rewards.count > 0) {
        NSString *msg = [KwizzadReward confirmationTextWithRewards: rewards];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle: nil
                                                                       message: msg
                                                                preferredStyle: UIAlertControllerStyleAlert];
        [alert addAction: [UIAlertAction actionWithTitle:@"Yay!" style: UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [openTransactions enumerateObjectsUsingBlock:^(KwizzadOpenTransaction * _Nonnull obj, BOOL * _Nonnull stop) {
                [kwizzadInstance completeWithTransaction: obj];
            }];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    else {
        // Silently confirm the transaction
        [openTransactions enumerateObjectsUsingBlock:^(KwizzadOpenTransaction * _Nonnull obj, BOOL * _Nonnull stop) {
            [kwizzadInstance completeWithTransaction: obj];
        }];
    }
}

// optional
-(void) kwizzadOnNoFillWithPlacementId:(NSString *)placementId {
    [self log:[NSString stringWithFormat:@"Received a no-fill response on placement %@",placementId]];
    [self.adView setHidden: YES];
    [_preloadButton setEnabled:YES];
}

// optional
-(void)kwizzadOnErrorOccuredWithPlacementId:(NSString *)placementId reason:(NSString *)reason {
    [self log:[NSString stringWithFormat:@"An error occured on placement %@: %@",placementId,reason]];
    [_adView setHidden:YES];
    [_preloadButton setEnabled:YES];
}

// optional
-(void) kwizzadWillPresentAdWithPlacementId:(NSString *)placementId {
    [self log:[NSString stringWithFormat:@"Kwizzad will present an ad on placement %@",placementId]];
}

// optional
-(void) kwizzadWillDismissAdWithPlacementId:(NSString *)placementId {
    [self log:[NSString stringWithFormat:@"Kwizzad will dismiss an ad on placement %@",placementId]];
}

// optional
-(void) kwizzadOnGoalReachedWithPlacementId:(NSString *)placementId {
    [self log:[NSString stringWithFormat:@"User reached the campaign goal on placement %@",placementId]];
}

// optional
-(void) kwizzadCallToActionClickedWithPlacementId:(NSString *)placementId {
    [self log:[NSString stringWithFormat:@"User reached the call-to-action on placement %@",placementId]];
}

/////////////////////////////////////////////////////////////////////

// Hide keyboard when click return.
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self preloadButtonPressed:self];
    [textField resignFirstResponder];
    return true;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [_placementField resignFirstResponder];
}

-(void) clearLog {
    _debugMessage.text = @"";
}

-(void) log:(NSString*)message {
    _debugMessage.text = [_debugMessage.text stringByAppendingString:[NSString stringWithFormat:@"\n\n%@",message]];
    CGPoint bottomOffset = CGPointMake(0, self.debugMessage.contentSize.height - self.debugMessage.bounds.size.height);
    [self.debugMessage setContentOffset:bottomOffset animated:YES];
    NSLog(@"%@", message);
}

@end
