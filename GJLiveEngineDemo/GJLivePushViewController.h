//
//  GJLivePushViewController.h
//  GJCaptureTool
//
//  Created by mac on 17/2/24.
//  Copyright © 2017年 MinorUncle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GJLiveEngine/GJLiveDefine.h>
@interface GJLivePushViewController : UIViewController
@property(nonatomic,copy)NSString* pullAddr;
@property(nonatomic,copy)NSString* pushAddr;
@property(nonatomic,assign)GJCaptureType type;

@end
