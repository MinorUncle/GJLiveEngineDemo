//
//  GJSunSystemARScene.m
//  GJCaptureTool
//
//  Created by melot on 2017/11/1.
//  Copyright © 2017年 MinorUncle. All rights reserved.
//

#import "GJSunSystemARScene.h"

@implementation GJSunSystemARScene
@synthesize isRunning = _isRunning;
- (instancetype)init
{
    self = [super init];
    if (self) {
        _controller = [[SCNViewController alloc]init];
        _scene = _controller.arRightView;
        _updateFps = 60;
    }
    return self;
}

-(void)setUpdateBlock:(ARUpdateBlock)updateBlock{
    _updateBlock = updateBlock;
    _controller.updateBlock = updateBlock;
}
-(void)rotateCamera{
    return ;
}
-(AVCaptureDevicePosition)cameraPosition{
    return  AVCaptureDevicePositionBack;
}

-(BOOL)startRun{
    _controller.view.backgroundColor = [UIColor redColor];
    [_controller.arSession runWithConfiguration:_controller.arSessionConfiguration options:ARSessionRunOptionRemoveExistingAnchors|ARSessionRunOptionResetTracking];
    _isRunning = YES;
    return YES;
}
-(void)stopRun{
    [_controller.arSession pause];
    _scene.scene.paused = YES;
    _isRunning = NO;
}

-(void)pause{
    [_controller.arSession pause];
    _scene.scene.paused = YES;
    _isRunning = NO;

}
-(BOOL)resume{
    [_controller.arSession runWithConfiguration:_controller.arSessionConfiguration options:0];
    _scene.scene.paused = NO;
    _isRunning = YES;
    return YES;
}

-(BOOL)isRunning{
    return _isRunning;
}

@end
