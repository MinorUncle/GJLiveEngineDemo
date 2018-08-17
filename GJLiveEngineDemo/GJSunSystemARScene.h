//
//  GJSunSystemARScene.h
//  GJCaptureTool
//
//  Created by melot on 2017/11/1.
//  Copyright © 2017年 MinorUncle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCNViewController.h"
#import <GJLiveEngine/GJLivePush.h>

@interface GJSunSystemARScene:NSObject<GJImageARScene>
@property(nonatomic,retain) SCNViewController* controller;
@property(nonatomic,retain,readonly) ARSCNView* scene;
@property(nonatomic,assign) NSInteger updateFps;
@property(readonly, nonatomic) BOOL isRunning;
@property(nonatomic,assign) ARUpdateBlock updateBlock;
- (AVCaptureDevicePosition)cameraPosition;
- (void)rotateCamera;

-(BOOL)startRun;
-(void)stopRun;
-(void)pause;
-(BOOL)resume;
@end

