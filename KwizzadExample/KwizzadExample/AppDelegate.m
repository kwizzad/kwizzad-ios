//
//  AppDelegate.m
//  KwizzadExample
//
//  Created by Anatol Ulrich on 14/10/2016.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

#import "AppDelegate.h"

#import <KwizzadSDK/KwizzadSDK-Swift.h>


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [KwizzadSDK setupWithConfiguration:[[KwizzadConfiguration alloc]initWithApiKey:@"b81e71a86cf1314d249791138d642e6c4bd08240f21dd31811dc873df5d7469d"
                                                                    overrideServer: NULL
                                                                    overrideWeb:NULL
                                                                    debug:YES]];
    return YES;
}

@end
