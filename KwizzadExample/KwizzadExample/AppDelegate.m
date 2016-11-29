//
//  AppDelegate.m
//  KwizzadExample
//
//  Created by Anatol Ulrich on 14/10/2016.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

#import "AppDelegate.h"

#import <KwizzadSDK/KwizzadSDK-Swift.h>

@interface AppDelegate ()

@property (nonatomic, retain) NSMutableArray *bag;

@end

@implementation AppDelegate

@synthesize bag;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [KwizzadSDK.instance configure:[
                                    [KwizzadConfiguration alloc]
                                    initWithApiKey:@"b81e71a86cf1314d249791138d642e6c4bd08240f21dd31811dc873df5d7469d"
                                    overrideServer:NULL
                                    overrideWeb:NULL
                                    debug:YES]
     ];
    
    NSLog(@">> kwizzad configured ");
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    bag = [[NSMutableArray alloc] init];
    
    // TODO: this is done more than once. Ok?
    /*[bag addObject:[KwizzadSDK.instance isInitializedSignalWithCallback:^(BOOL initialized) {
        NSLog(@">> initialized %d",initialized);
        // TODO: wait for ad request till init is done?
    }]];*/
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
