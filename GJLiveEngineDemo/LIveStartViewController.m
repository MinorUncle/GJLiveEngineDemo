//
//  LIveStartViewController.m
//  GJCaptureTool
//
//  Created by melot on 2017/8/23.
//  Copyright © 2017年 MinorUncle. All rights reserved.
//

#import "LIveStartViewController.h"
#import "GJLivePushViewController.h"

#define PULL_URL @"rtmp://live.hkstv.hk.lxdns.com/live/hks";

//请注释 #import "StreamAddr.h",自行通过以下宏配置推拉流地址。
//#define PUSH_URL
//#define PULL_URL
#import "StreamAddr.h"
@interface LIveStartViewController ()
{
    UIButton* _startBtn;
    UIButton* _arStartBtn;
    UIButton* _uiStartBtn;
    UIButton* _paintStartBtn;
    UITextField* _pushAddr;
    UITextField* _pullAddr;
    
}
@end

@implementation LIveStartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    int a[2] = {0};
//    a[2] = 2;
//    self.navigationController.navigationBarHidden = YES;
    self.view.backgroundColor = [UIColor whiteColor];

    int yCount = 6;
    CGFloat yPadding = 100;
    CGFloat height = 50;
    CGFloat marrgin = (self.view.bounds.size.height - yPadding*2 - yCount * height)/(yCount - 1);

    CGRect rect = CGRectMake(0, yPadding, 80, height);
    UILabel* leftLab = [[UILabel alloc]initWithFrame:rect];
    leftLab.text = @"拉流地址";
    [self.view addSubview:leftLab];
    
    rect.origin.y = CGRectGetMaxY(rect)+marrgin;
    leftLab = [[UILabel alloc]initWithFrame:rect];
    leftLab.text = @"推流地址";
    [self.view addSubview:leftLab];
    
    rect.origin.y = yPadding;
    rect.origin.x = leftLab.frame.size.width;
    rect.size.width = self.view.bounds.size.width - rect.size.width;

    _pullAddr = [[UITextField alloc]initWithFrame:rect];
    _pullAddr.borderStyle =  UITextBorderStyleRoundedRect;
#ifdef PULL_URL
    _pullAddr.text = PULL_URL;
#endif
    [self.view addSubview:_pullAddr];

    rect.origin.y = CGRectGetMaxY(rect)+marrgin;
    _pushAddr = [[UITextField alloc]initWithFrame:rect];
#ifdef PUSH_URL
    _pushAddr.text = PUSH_URL;
#endif
    _pushAddr.borderStyle =  UITextBorderStyleRoundedRect;
    [self.view addSubview:_pushAddr];
    
    rect.origin.y = CGRectGetMaxY(rect)+marrgin;
    rect.origin.x = 0;
    rect.size.width = self.view.bounds.size.width;
    _startBtn = [[UIButton alloc]initWithFrame:rect];
    [_startBtn addTarget:self action:@selector(startBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_startBtn setTitle:@"相机直播" forState:UIControlStateNormal];
    [_startBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:_startBtn];
    
    rect.origin.y = CGRectGetMaxY(rect)+marrgin;
    _arStartBtn = [[UIButton alloc]initWithFrame:rect];
    [_arStartBtn addTarget:self action:@selector(startBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_arStartBtn setTitle:@"AR直播" forState:UIControlStateNormal];
    [_arStartBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:_arStartBtn];
    
    rect.origin.y = CGRectGetMaxY(rect)+marrgin;
    _uiStartBtn = [[UIButton alloc]initWithFrame:rect];
    [_uiStartBtn addTarget:self action:@selector(startBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_uiStartBtn setTitle:@"view直播" forState:UIControlStateNormal];
    [_uiStartBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:_uiStartBtn];
    
    rect.origin.y = CGRectGetMaxY(rect)+marrgin;
    _paintStartBtn = [[UIButton alloc]initWithFrame:rect];
    [_paintStartBtn addTarget:self action:@selector(startBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_paintStartBtn setTitle:@"画笔直播" forState:UIControlStateNormal];
    [_paintStartBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:_paintStartBtn];
    // Do any additional setup after loading the view.
}
-(void)startBtn:(UIButton*)btn{
    NSString* pull = _pullAddr.text;
    NSString* push = _pushAddr.text;
    if (!pull || !pull) {
        return;
    }
//    NSString* path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
////    path = [path stringByAppendingPathComponent:@"demo.mp4"];
////
    GJLivePushViewController* c = [[GJLivePushViewController alloc]init];
//    pull = [[NSBundle mainBundle]pathForResource:@"ios" ofType:@"h264"];
    c.pullAddr = pull;
    c.pushAddr = push;
    
    if (btn == _arStartBtn) {
        c.type = kGJCaptureTypeAR;
    }else if (btn == _startBtn){
        c.type = kGJCaptureTypeCamera;
    }else if(btn == _paintStartBtn){
        c.type = kGJCaptureTypePaint;
    }else if (btn == _uiStartBtn){
        c.type = kGJCaptureTypeView;
    }
    [self.navigationController pushViewController:c animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
