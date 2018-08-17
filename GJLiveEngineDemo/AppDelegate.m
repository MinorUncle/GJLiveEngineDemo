//
//  AppDelegate.m
//  GJCaptureTool
//
//  Created by tongguan on 16/6/27.
//  Copyright © 2016年 MinorUncle. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "LIveStartViewController.h"
#import <GJLiveEngine/UncaughtExceptionHandler.h>
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifndef DEBUG
    [UncaughtExceptionHandler InstallUncaughtExceptionHandler];
#endif
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    
    LIveStartViewController* controller = [[LIveStartViewController alloc]init];
//    ViewController * controller = [[ViewController alloc]init];
    UINavigationController* nav = [[UINavigationController alloc]initWithRootViewController:controller];
//    nav.navigationBarHidden = YES;
    //设置背景透明图片
    [nav.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
//    //去掉 bar 下面有一条黑色的线
    [nav.navigationBar setShadowImage:[UIImage new]];
//    nav.navigationBar.userInteractionEnabled = NO;
//    nav.navigationBar.translucent = true;
//    [[[nav.navigationBar subviews] objectAtIndex:0] setAlpha:0];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

static int backgroundTaskCount = 0;
- (int)getBackgroundTaskCount {
    return backgroundTaskCount;
}

- (void)incrementBackgroundTaskCount {
    if (backgroundTaskCount >= 0) {
        backgroundTaskCount++;
    }
}

- (void)resetBackgroundTaskCount {
    backgroundTaskCount = 0;
}

UIBackgroundTaskIdentifier backgroundTask = 0;
UIBackgroundTaskIdentifier helperBackgroundTask = 0;
static int backgroundTaskTimeLimit = 0;
static const int MAXIMUM_BACKGROUND_TASKS = 2;

dispatch_block_t helperBackgroundTaskBlock = ^{
    [[NSThread currentThread] setName:@"helperBackgroundTaskBlock.init"];
    [[UIApplication sharedApplication] endBackgroundTask:helperBackgroundTask];
    helperBackgroundTask = UIBackgroundTaskInvalid;
    helperBackgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:helperBackgroundTaskBlock];
};


-(void)stopHelperBackgroundTask {
    NSLog(@"stopHelperBackgroundTask called");
    helperBackgroundTaskBlock = ^{
        [[NSThread currentThread] setName:@"helperBackgroundTaskBlock.stopped"];
        [[UIApplication sharedApplication] endBackgroundTask:helperBackgroundTask];
        helperBackgroundTask = UIBackgroundTaskInvalid;
    };
    if (helperBackgroundTask) {
        [[UIApplication sharedApplication] endBackgroundTask:helperBackgroundTask];
        helperBackgroundTask = UIBackgroundTaskInvalid;
    }
}

- (void)stopBackgroundTask {
    
    NSLog(@"stopBackgroundTask called");
    UIBackgroundTaskIdentifier identifier = backgroundTask;
    backgroundTask = 0;
    [[UIApplication sharedApplication] endBackgroundTask:identifier];
    
}
-(void)startHelperBackgroundTask {
    NSLog(@"startHelperBackgroundTask called");
    if (!helperBackgroundTaskBlock) {
        helperBackgroundTaskBlock = ^{
            [[NSThread currentThread] setName:@"helperBackgroundTaskBlock.started"];
            [[UIApplication sharedApplication] endBackgroundTask:helperBackgroundTask];
            helperBackgroundTask = UIBackgroundTaskInvalid;
        };
    }
    helperBackgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:helperBackgroundTaskBlock];
}
-(void)setBackgroundTaskTimeLimit {
    [self startHelperBackgroundTask];
    
    // Wait for background async task by 'OhadM':
    // http://stackoverflow.com/a/31893720
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @autoreleasepool {
            
            [[NSThread currentThread] setName:@"setBackgroundTaskTimeLimit.dispatch_async"];
            backgroundTaskTimeLimit = [[UIApplication sharedApplication ] backgroundTimeRemaining];
            NSLog(@"setBackgroundTaskTimeLimit to: %i", backgroundTaskTimeLimit);
            
        }
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [self stopHelperBackgroundTask];
}
-(void)doBackgroundTaskAsync:(SEL)selector {
    
    NSLog(@"doBackgroundTaskAsync called");
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground
        || [self getBackgroundTaskCount] >= MAXIMUM_BACKGROUND_TASKS) {
        NSLog(@"doBackgroundTaskAsync denied start");
        return;
    }
    
    [self startHelperBackgroundTask];
    
    [self incrementBackgroundTaskCount];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[NSThread currentThread] setName:@"doBackgroundTaskAsync.dispatch_async"];
        while ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
            NSLog(@"doBackgroundTaskAsync in while loop. TR: %f",  [[UIApplication sharedApplication] backgroundTimeRemaining]);
            [self performSelector: @selector(keepAlive)];
            sleep(5.0);
        }
        NSLog(@"doBackgroundTaskAsync task ended");
    });
}
- (void)applicationDidEnterBackground:(UIApplication *)application {
//    NSLog(@"handleBackgroundTasks called");
//    UIDevice *device = [UIDevice currentDevice];
//    BOOL backgroundSupported = NO;
//    if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
//        backgroundSupported = device.multitaskingSupported;
//    }
//    if (backgroundSupported) { // perform a background task
//        
//        [self setBackgroundTaskTimeLimit];
//        [self doBackgroundTaskAsync:@selector(keepAlive)];
//        [self performSelector:@selector(doBackgroundTaskAsync:) withObject:nil afterDelay:[self getBackgroundTaskStartupDelay]];
//        
//    }
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}
-(int)getBackgroundTaskStartupDelay {
    int target = 10;
    int startupDelay = 0;
    
    if (backgroundTaskTimeLimit >= target) {
        startupDelay = backgroundTaskTimeLimit - target;
    }
    
    return startupDelay;
}
-(void)keepAlive {
//    [AirFloatSharedAppDelegate startRaopServer];
    NSLog(@"keepAlive");
}
- (void)applicationWillEnterForeground:(UIApplication *)application {
//    NSLog(@"handleForegroundTasks called");
//    [self resetBackgroundTaskCount];
//    [self stopHelperBackgroundTask];
//    [self stopBackgroundTask];

    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
