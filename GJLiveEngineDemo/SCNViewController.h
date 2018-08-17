//
//  SCNViewController.h
//  ARPlayDemo
//
//  Created by alexyang on 2017/7/11.
//  Copyright © 2017年 alexyang. All rights reserved.
//

#import <UIKit/UIKit.h>
//3D游戏框架
#import <SceneKit/SceneKit.h>
//ARKit框架
#import <ARKit/ARKit.h>
typedef void(^ARUpdateBlock)();

@interface SCNViewController : UIViewController
@property(nonatomic, assign) BOOL isCardBoard;
//AR视图：展示3D界面
@property (nonatomic, strong)ARSCNView *arSCNView;
@property (nonatomic, strong)ARSCNView *arLeftView;
@property (nonatomic, strong)ARSCNView *arRightView;
@property(nonatomic,copy) ARUpdateBlock updateBlock;

//AR会话，负责管理相机追踪配置及3D相机坐标
@property(nonatomic,strong)ARSession *arSession;

//会话追踪配置
@property(nonatomic,strong)ARWorldTrackingConfiguration *arSessionConfiguration;

@end
