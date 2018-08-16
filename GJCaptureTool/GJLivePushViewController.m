//
//  GJLivePushViewController.m
//  GJCaptureTool
//
//  Created by mac on 17/2/24.
//  Copyright © 2017年 MinorUncle. All rights reserved.
//

#import "GJLivePushViewController.h"
#import <GJLiveEngine/GJLiveEngine.h>
#import <AVFoundation/AVFoundation.h>
#import "GJSunSystemARScene.h"
#import <ARKit/ARConfiguration.h>
#import "ZipArchive/ZipArchive.h"

//#define PUSH_TIP_SHOW 1
//#define PULL_TIP_SHOW 1


@interface GJSliderView:UISlider{
    UILabel * _titleLab;
    UILabel * _valueLab;
    
}
@property(nonatomic,copy)NSString* title;
@end
@implementation GJSliderView
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _titleLab = [[UILabel alloc]init];
        [_titleLab setFont:[UIFont systemFontOfSize:15]];
        [_titleLab setTextColor:[UIColor whiteColor]];
        [_titleLab setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:_titleLab];
        _valueLab = [[UILabel alloc]init];
        [_valueLab setFont:[UIFont systemFontOfSize:12]];
        [_valueLab setTextAlignment:NSTextAlignmentCenter];
        [_valueLab setTextColor:[UIColor whiteColor]];
        self.value = 0;
        [self addSubview:_valueLab];
        
    }
    return self;
}

-(void)setValue:(float)value{
    [super setValue:value];
    _valueLab.text = [NSString stringWithFormat:@"%0.2f",value];
}

-(void)setValue:(float)value animated:(BOOL)animated{
    [super setValue:value animated:animated];
    _valueLab.text = [NSString stringWithFormat:@"%0.2f",value];
}
#define xRate 0.3
#define yRate 0.5

-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    CGRect rect = frame;
    rect.origin = CGPointZero;
    rect.size.width = frame.size.width * xRate;
    _titleLab.frame = rect;
    
    rect.origin.x = CGRectGetMaxX(rect);
    rect.size.width = frame.size.width*(1-xRate);
    rect.size.height = frame.size.height * yRate;
    _valueLab.frame = rect;
}

-(void)setTitle:(NSString *)title{
    [_titleLab setText:title];
}

-(NSString *)title{
    return _titleLab.text;
}

-(CGRect)trackRectForBounds:(CGRect)bounds{
    CGRect rect = bounds;
    rect.size.height = 3;
    rect.size.width = bounds.size.width * (1-xRate);
    rect.origin.x = bounds.size.width - rect.size.width;
    rect.origin.y = (bounds.size.height - rect.size.height)* yRate;
    return rect;
};

@end

@interface PushManager : NSObject <GJLivePushDelegate>
{
    NSDictionary* _videoSize;
    NSMutableArray<UIView*>* _tipViewsArry;
    NSMutableArray<UIView*>* _btnViewsArry;
    UITapGestureRecognizer* _tapGesture;
    UIScrollView*   _contentView;
    NSArray<NSString*>* _stickerPath;

}

@property (strong, nonatomic) GJLivePush *livePush;
@property (copy, nonatomic) NSString* pushAddr;

@property (strong, nonatomic) UIButton *paintBtn;
@property (strong, nonatomic) UIButton *pushStartBtn;
@property (strong, nonatomic) UIButton *audioMixBtn;
@property (strong, nonatomic) UIButton *earPlay;
@property (strong, nonatomic) UIButton *mixStream;
@property (strong, nonatomic) UIButton *changeCamera;
@property (strong, nonatomic) UIButton *audioMute;
@property (strong, nonatomic) UIButton *videoMute;
@property (strong, nonatomic) UIButton *uiRecode;
@property (strong, nonatomic) UIButton *reverb;
@property (strong, nonatomic) UIButton *messureModel;
@property (strong, nonatomic) UIButton *sticker;
@property (strong, nonatomic) UIButton *sizeChangeBtn;
@property (strong, nonatomic) UIButton *aecBtn;
@property (strong, nonatomic) UIButton *preMirror;
@property (strong, nonatomic) UIButton *streamMirror;
@property (strong, nonatomic) UIButton *faceSticker;

@property (strong, nonatomic) UIView *view;

@property(strong, nonatomic) UIView* tipContent;

@property (strong, nonatomic) GJSliderView *inputGain;

@property (strong, nonatomic) GJSliderView *mixGain;

@property (strong, nonatomic) GJSliderView *outputGain;
@property (strong, nonatomic) GJSliderView *skinSoft;
@property (strong, nonatomic) GJSliderView *skinRubby;
@property (strong, nonatomic) GJSliderView *faceSlider;
@property (strong, nonatomic) GJSliderView *skinBriness;
@property (strong, nonatomic) GJSliderView *eyeBig;

@property (strong, nonatomic) UILabel *fpsLab;
@property (strong, nonatomic) UILabel *vSendRateLab;
@property (strong, nonatomic) UILabel *aSendRateLab;

@property (strong, nonatomic) UILabel *pushStateLab;

@property (strong, nonatomic) UILabel *delayVLab;
@property (strong, nonatomic) UILabel *delayALab;
@property (strong, nonatomic) UILabel *currentV;
@property (strong, nonatomic) UILabel *timeLab;
@property (assign, nonatomic) CGRect frame;
@property (assign, nonatomic) CGRect beforeFullframe;
@property (assign, nonatomic) BOOL enableFull;

@end
@implementation PushManager
- (instancetype)initWithPushUrl:(NSString*)url type:(GJCaptureType)type
{
    self = [super init];
    if (self) {
        _tipViewsArry = [NSMutableArray array];
        _btnViewsArry = [NSMutableArray array];

        _pushAddr = url;
        _videoSize = @{
                       @"360*480":[NSValue valueWithCGSize:CGSizeMake(360, 480)],
                       @"540*960":[NSValue valueWithCGSize:CGSizeMake(540, 960)],
//                       @"480*640":[NSValue valueWithCGSize:CGSizeMake(480, 640)],
                       @"720*1280":[NSValue valueWithCGSize:CGSizeMake(720, 1280)]
                       };
        _stickerPath = @[@"bear",@"bd",@"hkbs",@"lb",@"null"];

        GJPushConfig config = {0};
        config.mAudioChannel = 1;
        config.mAudioSampleRate = 44100;
        CGSize pushSize = [_videoSize.allValues.firstObject CGSizeValue];
        
        config.mPushSize = (GSize){pushSize.width,pushSize.height};
        
        config.mVideoBitrate = 8*80*1024;
        if (type == kGJCaptureTypePaint) {
            config.mFps = 30;
        }else{
            config.mFps = 15;
        }
        config.mAudioBitrate = 64*1000;
        _livePush = [[GJLivePush alloc]init];
        _livePush.captureType = type;
        [_livePush setPushConfig:config];
        //        _livePush.enableAec = YES;
        _livePush.delegate = self;
        _livePush.cameraPosition = GJCameraPositionFront;
        NSString* path = [[NSBundle mainBundle]pathForResource:@"track_data" ofType:@"dat"];
        [_livePush prepareVideoEffectWithBaseData:path];
//
//        _livePush.eyeEnlargement = 50;
//        _livePush.skinSoften = 50;
//        _livePush.faceSlender = 50;
//        _livePush.brightness = 50;
//        _livePush.skinRuddy = 50;
        
        [self buildUI];
        
    }
    return self;
}
-(void)setEnableFull:(BOOL)enableFull{
    _tapGesture.enabled = enableFull;
}
-(void)buildUI{
    self.view = [[UIView alloc]init];
//    _timeLab = [[UILabel alloc]init];
//    [self.view addSubview:_timeLab];
    
    _livePush.previewView.contentMode = UIViewContentModeScaleAspectFit;
    _livePush.previewView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_livePush.previewView];
    
    _contentView = [[UIScrollView alloc]init];
    
    [self.view addSubview:_contentView];
    
    _pushStartBtn = [[UIButton alloc]init];
    [_pushStartBtn setTitle:@"推流开始" forState:UIControlStateNormal];
    [_pushStartBtn setTitle:@"推流结束" forState:UIControlStateSelected];
    [_pushStartBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_pushStartBtn setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
    [_pushStartBtn addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_pushStartBtn];
    [_btnViewsArry addObject:_pushStartBtn];
    
    _tipContent = [[UIView alloc]init];
    
#ifdef PUSH_TIP_SHOW
    [self.view addSubview:_tipContent];
#endif
    
    _pushStateLab = [[UILabel alloc]init];
    _pushStateLab.text = @"推流未连接";
    _pushStateLab.textColor = [UIColor redColor];
    _pushStateLab.font = [UIFont systemFontOfSize:10];
    [_tipContent addSubview:_pushStateLab];
    [_tipViewsArry addObject:_pushStateLab];

    _fpsLab = [[UILabel alloc]init];
    _fpsLab.textColor = [UIColor redColor];
    _fpsLab.font = [UIFont systemFontOfSize:10];
    _fpsLab.text = @"FPS V:0,A:0";
    [_tipContent addSubview:_fpsLab];
    [_tipViewsArry addObject:_fpsLab];

    _vSendRateLab = [[UILabel alloc]init];
    _vSendRateLab.textColor = [UIColor redColor];
    _vSendRateLab.text = @"V BPS P:0 E:0";
    _vSendRateLab.font = [UIFont systemFontOfSize:10];
    [_tipContent addSubview:_vSendRateLab];
    [_tipViewsArry addObject:_vSendRateLab];
    
    _aSendRateLab = [[UILabel alloc]init];
    _aSendRateLab.textColor = [UIColor redColor];
    _aSendRateLab.text = @"A BPS P:0 E:0";
    _aSendRateLab.font = [UIFont systemFontOfSize:10];
    [_tipContent addSubview:_aSendRateLab];
    [_tipViewsArry addObject:_aSendRateLab];

    _delayVLab = [[UILabel alloc]init];
    _delayVLab.textColor = [UIColor redColor];
    _delayVLab.font = [UIFont systemFontOfSize:10];
    _delayVLab.text = @"cache V t:0 ms f:0";
    [_tipContent addSubview:_delayVLab];
    [_tipViewsArry addObject:_delayVLab];

    _delayALab = [[UILabel alloc]init];
    _delayALab.textColor = [UIColor redColor];
    _delayALab.font = [UIFont systemFontOfSize:10];
    _delayALab.text = @"cache A t:0 ms f:0";
    [_tipContent addSubview:_delayALab];
    [_tipViewsArry addObject:_delayALab];

    _currentV = [[UILabel alloc]init];
    _currentV.textColor = [UIColor redColor];
    _currentV.font = [UIFont systemFontOfSize:10];
    _currentV.text = @"encode V b:0 kB/s f:0";
    [_tipContent addSubview:_currentV];
    [_tipViewsArry addObject:_currentV];

    
    _audioMixBtn = [[UIButton alloc]init];
    _audioMixBtn.backgroundColor = [UIColor clearColor];
    [_audioMixBtn setTitle:@"开始混音" forState:UIControlStateNormal];
    [_audioMixBtn setTitle:@"结束混音" forState:UIControlStateSelected];
    [_audioMixBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_audioMixBtn addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_audioMixBtn];
    [_btnViewsArry addObject:_audioMixBtn];

    _earPlay = [[UIButton alloc]init];
    _earPlay.backgroundColor = [UIColor clearColor];
    [_earPlay setTitle:@"开始耳返" forState:UIControlStateNormal];
    [_earPlay setTitle:@"结束耳返" forState:UIControlStateSelected];
    [_earPlay setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_earPlay addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_earPlay];
    [_btnViewsArry addObject:_earPlay];

    _mixStream = [[UIButton alloc]init];
    _mixStream.backgroundColor = [UIColor clearColor];
    [_mixStream setTitle:@"禁止混音入流" forState:UIControlStateNormal];
    [_mixStream setTitle:@"允许混音入流" forState:UIControlStateSelected];
    [_mixStream setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_mixStream addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_mixStream];
    [_btnViewsArry addObject:_mixStream];

    _changeCamera = [[UIButton alloc]init];
    _changeCamera.backgroundColor = [UIColor clearColor];
    [_changeCamera setTitle:@"切换相机" forState:UIControlStateNormal];
    [_changeCamera setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_changeCamera addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_changeCamera];
    [_btnViewsArry addObject:_changeCamera];

    _preMirror = [[UIButton alloc]init];
    _preMirror.backgroundColor = [UIColor clearColor];
    [_preMirror setTitle:@"预览镜像" forState:UIControlStateNormal];
    [_preMirror setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_preMirror addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_preMirror];
    [_btnViewsArry addObject:_preMirror];
    
    _streamMirror = [[UIButton alloc]init];
    _streamMirror.backgroundColor = [UIColor clearColor];
    [_streamMirror setTitle:@"推流镜像" forState:UIControlStateNormal];
    [_streamMirror setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_streamMirror addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_streamMirror];
    [_btnViewsArry addObject:_streamMirror];
    
    _faceSticker = [[UIButton alloc]init];
    _faceSticker.backgroundColor = [UIColor clearColor];
    [_faceSticker setTitle:@"开启人脸贴纸" forState:UIControlStateNormal];
    [_faceSticker setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_faceSticker addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_faceSticker];
    [_btnViewsArry addObject:_faceSticker];

    
    _videoMute = [[UIButton alloc]init];
    _videoMute.backgroundColor = [UIColor clearColor];
    [_videoMute setTitle:@"暂停视频" forState:UIControlStateNormal];
    [_videoMute setTitle:@"开启视频" forState:UIControlStateSelected];
    [_videoMute setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_videoMute addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_videoMute];
    [_btnViewsArry addObject:_videoMute];

    _audioMute = [[UIButton alloc]init];
    _audioMute.backgroundColor = [UIColor clearColor];
    [_audioMute setTitle:@"暂停音频" forState:UIControlStateNormal];
    [_audioMute setTitle:@"开启音频" forState:UIControlStateSelected];
    [_audioMute setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_audioMute addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_audioMute];
    [_btnViewsArry addObject:_audioMute];

//    _uiRecode = [[UIButton alloc]init];
//    _uiRecode.backgroundColor = [UIColor clearColor];
//    [_uiRecode setTitle:@"开始UI录制" forState:UIControlStateNormal];
//    [_uiRecode setTitle:@"结束UI录制" forState:UIControlStateSelected];
//    [_uiRecode setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
//    [_uiRecode addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
//    _uiRecode.backgroundColor = [UIColor clearColor];
//    [_contentView addSubview:_uiRecode];
    
    _reverb = [[UIButton alloc]init];
    _reverb.backgroundColor = [UIColor clearColor];
    [_reverb setTitle:@"开启混响" forState:UIControlStateNormal];
    [_reverb setTitle:@"关闭混响" forState:UIControlStateSelected];
    [_reverb setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_reverb addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_reverb];
    [_btnViewsArry addObject:_reverb];

    _messureModel = [[UIButton alloc]init];
    _messureModel.backgroundColor = [UIColor clearColor];
    [_messureModel setTitle:@"开启messure模式" forState:UIControlStateNormal];
    [_messureModel setTitle:@"关闭messure模式" forState:UIControlStateSelected];
    [_messureModel setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_messureModel addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_messureModel];
    [_btnViewsArry addObject:_messureModel];

    _sticker = [[UIButton alloc]init];
    _sticker.backgroundColor = [UIColor clearColor];
    [_sticker setTitle:@"开始贴纸" forState:UIControlStateNormal];
    [_sticker setTitle:@"结束贴纸" forState:UIControlStateSelected];
    [_sticker setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_sticker addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_sticker];
    [_btnViewsArry addObject:_sticker];

    _aecBtn = [[UIButton alloc]init];
    _aecBtn.backgroundColor = [UIColor clearColor];
    [_aecBtn setTitle:@"开启回声消除" forState:UIControlStateNormal];
    [_aecBtn setTitle:@"关闭回声消除" forState:UIControlStateSelected];
    [_aecBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_aecBtn addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_aecBtn];
    [_btnViewsArry addObject:_aecBtn];

    _sizeChangeBtn = [[UIButton alloc]init];
    _sizeChangeBtn.backgroundColor = [UIColor clearColor];
    [_sizeChangeBtn setTitle:_videoSize.allKeys[0] forState:UIControlStateNormal];
    [_sizeChangeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_sizeChangeBtn addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    _sizeChangeBtn.backgroundColor = [UIColor clearColor];
    [_contentView addSubview:_sizeChangeBtn];
    [_btnViewsArry addObject:_sizeChangeBtn];

    _inputGain = [[GJSliderView alloc]init];
    _inputGain.title = @"采集音量:0";
    _inputGain.maximumValue = 1.0;
    _inputGain.minimumValue = 0.0;
//    _inputGain.continuous = NO;
    [_inputGain addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
    _inputGain.value = 1.0;
    [_contentView addSubview:_inputGain];
    [_btnViewsArry addObject:_inputGain];
    
    _mixGain = [[GJSliderView alloc]init];
    _mixGain.maximumValue = 1.0;
    _mixGain.minimumValue = 0.0;
    _mixGain.title = @"混音音量";
//    _mixGain.continuous = NO;
    [_mixGain addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
    _mixGain.value = 1.0;
    [_contentView addSubview:_mixGain];
    [_btnViewsArry addObject:_mixGain];

    _outputGain = [[GJSliderView alloc]init];
    _outputGain.maximumValue = 1.0;
    _outputGain.minimumValue = 0.0;
    _outputGain.title = @"总音量";
//    _outputGain.continuous = NO;
    [_outputGain addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
    _outputGain.value = 1.0;
    [_contentView addSubview:_outputGain];
    [_btnViewsArry addObject:_outputGain];

    _eyeBig = [[GJSliderView alloc]init];
    _eyeBig.maximumValue = 100.0;
    _eyeBig.minimumValue = 0.0;
    _eyeBig.title = @"大眼";
    //    _outputGain.continuous = NO;
    [_eyeBig addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
    _eyeBig.value = _livePush.eyeEnlargement;
    [_contentView addSubview:_eyeBig];
    [_btnViewsArry addObject:_eyeBig];
    
    _faceSlider = [[GJSliderView alloc]init];
    _faceSlider.maximumValue = 100.0;
    _faceSlider.minimumValue = 0.0;
    _faceSlider.title = @"瘦脸";
    //    _outputGain.continuous = NO;
    _faceSlider.value = _livePush.faceSlender;
    [_faceSlider addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
    _faceSlider.value = _livePush.faceSlender;
    [_contentView addSubview:_faceSlider];
    [_btnViewsArry addObject:_faceSlider];
    
    _skinBriness = [[GJSliderView alloc]init];
    _skinBriness.maximumValue = 100.0;
    _skinBriness.minimumValue = 0.0;
    _skinBriness.title = @"美白";
    //    _outputGain.continuous = NO;
    [_skinBriness addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
    _skinBriness.value = _livePush.brightness;
    [_contentView addSubview:_skinBriness];
    [_btnViewsArry addObject:_skinBriness];
    
    _skinRubby = [[GJSliderView alloc]init];
    _skinRubby.maximumValue = 100.0;
    _skinRubby.minimumValue = 0.0;
    _skinRubby.title = @"红润";
    //    _outputGain.continuous = NO;
    [_skinRubby addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
    _skinRubby.value = _livePush.skinRuddy;
    [_contentView addSubview:_skinRubby];
    [_btnViewsArry addObject:_skinRubby];
    
    _skinSoft = [[GJSliderView alloc]init];
    _skinSoft.maximumValue = 100.0;
    _skinSoft.minimumValue = 0.0;
    _skinSoft.title = @"磨皮";
    //    _outputGain.continuous = NO;
    [_skinSoft addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
    _skinSoft.value = _livePush.skinSoften;
    [_contentView addSubview:_skinSoft];
    [_btnViewsArry addObject:_skinSoft];
    
    if (_livePush.captureType == kGJCaptureTypePaint) {
        _paintBtn = [[UIButton alloc]init];
        [_paintBtn setTitle:@"全屏" forState:UIControlStateNormal];
        [_paintBtn setTitle:@"恢复" forState:UIControlStateSelected];
        [_paintBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_paintBtn setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
        [_paintBtn addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_paintBtn];
    }else{
        _tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(fullTap:)];
        _tapGesture.numberOfTouchesRequired = 2;
        [_view addGestureRecognizer:_tapGesture];
        for (UIGestureRecognizer* g in _outputGain.gestureRecognizers) {
            [_tapGesture requireGestureRecognizerToFail:g];
        }
        
        for (UIGestureRecognizer* g in _inputGain.gestureRecognizers) {
            [_tapGesture requireGestureRecognizerToFail:g];
        }
        
        for (UIGestureRecognizer* g in _mixGain.gestureRecognizers) {
            [_tapGesture requireGestureRecognizerToFail:g];
        }
    }
    
    
}
- (UIViewController *)findViewController:(UIView *)sourceView
{
    id target=sourceView;
    while (target) {
        target = ((UIResponder *)target).nextResponder;
        if ([target isKindOfClass:[UIViewController class]]) {
            break;
        }
    }
    return target;
}
-(void)setFrame:(CGRect )frame{
    _frame = frame;
    self.view.frame = frame;
    
    CGRect rect = self.view.bounds;
    _livePush.previewView.frame = rect;
    [_messureModel sizeToFit];
    CGSize size =  _messureModel.bounds.size;
    
    
    CGFloat hOffset = CGRectGetMaxY([self findViewController:self.view].navigationController.navigationBar.frame);
    
    NSInteger leftCount = _tipViewsArry.count;
    
    if (_livePush.captureType == kGJCaptureTypePaint) {
        rect.size.width = frame.size.width * 0.4;
        rect.size.height = (frame.size.height-hOffset) / leftCount;
        if(rect.size.height > 50)rect.size.height = 50;
        rect.origin.x = frame.size.width*0.3;
        rect.origin.y = hOffset;
        _paintBtn.frame = rect;
    }
    
    rect.origin = CGPointMake(0, hOffset);
    rect.size = CGSizeMake(size.width*0.4, self.view.bounds.size.height - hOffset);
    _tipContent.frame = rect;

    rect.origin = CGPointMake(0, 0);
    rect.size = CGSizeMake(frame.size.width*0.4, (frame.size.height-hOffset) / leftCount);
    
    for (UIView* view in _tipViewsArry) {
        view.frame = rect;
        rect.origin.y = CGRectGetMaxY(rect);
    }
    
    
#define ITEM_H 40
    rect.origin = CGPointMake(size.width, hOffset);
    rect.size = CGSizeMake(frame.size.width - size.width, self.view.bounds.size.height - hOffset);
    _contentView.frame = rect;
    
    rect.origin = CGPointZero;
    rect.size.height = ITEM_H;
    
    for (UIView* view in _btnViewsArry) {
        view.frame = rect;
        rect.origin.y = CGRectGetMaxY(rect);
    }
   
    _contentView.contentSize = CGSizeMake(size.width, ITEM_H*_btnViewsArry.count);
}

-(void)valueChange:(UISlider*)slider{
    if (slider == _inputGain) {
        _inputGain.title = [NSString stringWithFormat:@"采集音量：%0.2f",slider.value];
        [_livePush setInputVolume:slider.value];
    }else if (slider == _mixGain){
        _mixGain.title = [NSString stringWithFormat:@"混音音量：%0.2f",slider.value];
        [_livePush setMixVolume:slider.value];
        
    }else if (slider == _outputGain){
        _outputGain.title = [NSString stringWithFormat:@"输出音量：%0.2f",slider.value];
        [_livePush setMasterOutVolume:slider.value];
    }else if (slider == _skinSoft){
        _skinSoft.title = [NSString stringWithFormat:@"磨皮：%d",(int)slider.value];
        _livePush.skinSoften = slider.value;
    }else if (slider == _skinBriness){
        _skinBriness.title = [NSString stringWithFormat:@"美白：%d",(int)slider.value];
        _livePush.brightness = slider.value;
    }else if (slider == _skinRubby){
        _skinRubby.title = [NSString stringWithFormat:@"红润：%d",(int)slider.value];
        _livePush.skinRuddy = slider.value;
    }else if (slider == _eyeBig){
        _eyeBig.title = [NSString stringWithFormat:@"大眼：%d",(int)slider.value];
        _livePush.eyeEnlargement = slider.value;
    }else if (slider == _faceSlider){
        _faceSlider.title = [NSString stringWithFormat:@"瘦脸：%d",(int)slider.value];
        _livePush.faceSlender = slider.value;
    }
}

-(void)fullTap:(UITapGestureRecognizer*)tap{
    [UIView animateWithDuration:0.4 animations:^{
        [_view.superview bringSubviewToFront:_view];
        if(!CGRectEqualToRect(_frame, [UIScreen mainScreen].bounds)){
            _beforeFullframe = _frame;
            self.frame = [UIScreen mainScreen].bounds;
        }else{
            self.frame = _beforeFullframe;
        }
    }];
}

-(void)takeSelect:(UIButton*)btn{
    btn.selected = !btn.selected;
    if (btn == _paintBtn) {
        if (btn.selected) {
            [UIView animateWithDuration:0.4 animations:^{
                for (UIView* view in _view.superview.subviews) {
                    if (view != _view) {
                        view.alpha = 0;
                    }
                }
                for (UIView* view in _view.subviews) {
                    if (view != _paintBtn && view != _livePush.previewView) {
                        view.alpha = 0;
                    }
                }
                _beforeFullframe = _frame;
                self.frame = [UIScreen mainScreen].bounds;
            }];
        }else{
            [UIView animateWithDuration:0.4 animations:^{
                for (UIView* view in _view.subviews) {
                    if (view != _paintBtn && view != _livePush.previewView) {
                        view.alpha = 1;
                    }
                }
                for (UIView* view in _view.superview.subviews) {
                    if (view != _view) {
                        view.alpha = 1;
                    }
                }
                self.frame = _beforeFullframe;
            }];
        }
        
    }else if (btn == _aecBtn) {
        [_livePush setEnableAec:btn.selected];
//        if (btn.selected) {
//            NSMutableArray<UIImage*>* images = [NSMutableArray arrayWithCapacity:6];
//            images[0] = [UIImage imageNamed:[NSString stringWithFormat:@"%d.png",1]];
//
//            CGSize size = _livePush.captureSize;
//            GCRect rect = {size.width*0.2,size.height*0.5,100.0,100.0};
//            [_livePush startTrackingImageWithImages:images initFrame:rect];
//        }else{
//            [_livePush stopTracking];
//        }
    }else if (btn == _sizeChangeBtn) {
        btn.selected = NO;
        btn.tag++;
        NSInteger dex = btn.tag % _videoSize.allKeys.count;
        [btn setTitle:_videoSize.allKeys[dex] forState:UIControlStateNormal];
        GJPushConfig config = _livePush.pushConfig;
        CGSize size = [_videoSize[_videoSize.allKeys[dex]] CGSizeValue];
        config.mPushSize.height = size.height;
        config.mPushSize.width = size.width;
        [_livePush setPushConfig:config];
        
    }else  if (btn == _sticker) {
        if (btn.selected) {
            
            CGRect rect = CGRectMake(0, 0, 360, 100);

            NSMutableArray<GJOverlayAttribute*>* overlays = [NSMutableArray arrayWithCapacity:6];
            CGRect frame = {_livePush.captureSize.width*0.5,_livePush.captureSize.height*0.5,rect.size.width,rect.size.height};
            for (int i = 0; i< 1; i++) {
                overlays[0] = [GJOverlayAttribute overlayAttributeWithImage:[self getSnapshotImageWithSize:rect.size] frame:frame rotate:0];
            }
            __weak PushManager* wkSelf = self;
            [_livePush startStickerWithImages:overlays fps:15 updateBlock:^ void(NSInteger index,const GJOverlayAttribute* ioAttr, BOOL *ioFinish) {
                
                *ioFinish = NO;
                if (*ioFinish) {
                    btn.selected = NO;
                }
                static CGFloat r;
                r += 1;
//                static UIImage* image ;
//                if (image != nil) {
//                    ioAttr.image = image;
//                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//                        image = [wkSelf getSnapshotImageWithSize:rect.size];
//                    });
//                }else{
//                    image = [wkSelf getSnapshotImageWithSize:rect.size];
//                }
                UIImage* image = [wkSelf getSnapshotImageWithSize:rect.size];
                if (image) {
                    ioAttr.image  = image;
                }
                ioAttr.rotate = r;
            }];
            
            //            NSMutableArray<UIImage*>* images = [NSMutableArray arrayWithCapacity:6];
            //            for (int i = 0; i< 1 ; i++) {
            //                images[i] = [UIImage imageNamed:[NSString stringWithFormat:@"%d.png",i]];
            //            }
            //            CGSize size = _livePush.captureSize;
            //            GCRect rect = {size.width*0.5,size.height*0.5,100.0,100.0};
            //            GJStickerAttribute* attr = [GJStickerAttribute stickerAttributWithFrame:rect rotate:0];
            //            [_livePush startStickerWithImages:images attribure:attr fps:15 updateBlock:^GJStickerAttribute *(NSInteger index, BOOL *ioFinish) {
            //                GCRect re = rect;
            //                re.size.width = images[index].size.width;
            //                re.size.height = images[index].size.height;
            //                *ioFinish = NO;
            //                if (*ioFinish) {
            //                    btn.selected = NO;
            //                }
            //                static CGFloat r;
            //                r += 5;
            //                return [GJStickerAttribute stickerAttributWithFrame:re rotate:r];
            //            }];
        }else{
            [_livePush chanceSticker];
        }
        
        
    }else if (btn == _messureModel) {
        _livePush.measurementMode = btn.selected;
    }else if (btn == _reverb) {
        [_livePush enableReverb:btn.selected];
    }else if (btn == _uiRecode) {
        if (btn.selected) {
            NSString* path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
            path = [path stringByAppendingPathComponent:@"test.flv"];
            if(![_livePush startUIRecodeWithRootView:self.view fps:15 filePath:[NSURL fileURLWithPath:path]]){
                btn.selected = NO;
            }
        }else{
            [_livePush stopUIRecode];
            btn.enabled = NO;
        }
        
    }else if (btn == _audioMute) {
        _livePush.audioMute = btn.selected;
    }else if (btn == _videoMute) {
        _livePush.videoMute = btn.selected;
    }else if(btn == _audioMixBtn){
        if (btn.selected) {
            NSURL* path = [[NSBundle mainBundle]URLForResource:@"MixTest" withExtension:@"mp3"];
            if(![_livePush startAudioMixWithFile:path]){
                btn.selected = !btn.selected;
            }
            
        }else{
            [_livePush stopAudioMix];
        }
    }else if(btn == _earPlay){
        [_livePush enableAudioInEarMonitoring:btn.selected];
    }else if(btn == _mixStream){
        _livePush.mixFileNeedToStream = !btn.selected;
    }else  if(btn == _changeCamera){
        if (_livePush.cameraPosition == GJCameraPositionBack) {
            _livePush.cameraPosition = GJCameraPositionFront;
            _livePush.cameraMirror = YES;
            
        }else{
            _livePush.cameraPosition = GJCameraPositionBack;
            _livePush.cameraMirror = NO;
        }
        
    }else if (btn == _pushStartBtn) {
        if (btn.selected) {
            
            NSString* path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
            path = [path stringByAppendingPathComponent:@"test.mp4"];
            _sizeChangeBtn.enabled = NO;
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                if(![_livePush startStreamPushWithUrl:_pushAddr]){
                    [_livePush stopStreamPush];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        btn.selected = NO;
                        _sizeChangeBtn.enabled = YES;
                    });
                }
            });

        }else{
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [_livePush stopStreamPush];
            });
            _sizeChangeBtn.enabled = YES;
        }
    }else if (btn == _preMirror){
        _livePush.previewMirror = btn.selected;
    }else if (btn == _streamMirror){
        _livePush.streamMirror = btn.selected;
    }else if (btn == _faceSticker){
        NSString* zpath = [[NSBundle mainBundle]pathForResource:_stickerPath[btn.tag%_stickerPath.count] ofType:@"zip"];
        NSString*   unzipPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        NSString* destPath = [unzipPath stringByAppendingPathComponent:_stickerPath[btn.tag%_stickerPath.count]];
        
        BOOL isDir;
        BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:destPath isDirectory:&isDir];
        
        if (!exist || !isDir) {
            ZipArchive* zip = [[ZipArchive alloc]init];
            if([zip UnzipOpenFile:zpath]){
                if (![zip UnzipFileTo:unzipPath overWrite:NO]) {
                    printf("error\n");
                }
                [zip UnzipCloseFile];
            };
        }
        
        if (zpath) {
            NSString* path = [[NSBundle mainBundle]pathForResource:@"track_data" ofType:@"dat"];
            [_livePush prepareVideoEffectWithBaseData:path];
            [_livePush updateFaceStickTemplatePath:destPath];
            [_faceSticker setTitle:[NSString stringWithFormat:@"人脸贴图:%@",_stickerPath[btn.tag%_stickerPath.count]] forState:UIControlStateNormal];
        }else{
            [_livePush updateFaceStickTemplatePath:nil];
//            [_livePush chanceVideoEffect];
            [_faceSticker setTitle:@"人脸贴图:无" forState:UIControlStateNormal];
        }
        btn.tag ++;
        
    }
}


-(UIImage*)getSnapshotImageWithSize:(CGSize)size{
    static   NSDateFormatter *formatter ;
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd hh:mm:ss:SSS"];
    }
  
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    NSDictionary* attr = @{NSFontAttributeName:[UIFont systemFontOfSize:20]};

    static CGPoint fontPoint ;
    if (fontPoint.y < 0.0001) {
        CGSize fontSize = [dateTime sizeWithAttributes:attr];
        fontPoint.x = (size.width - fontSize.width)*0.5;
        fontPoint.y = (size.height - fontSize.height)*0.5;
    }
//    _timeLab.text = dateTime;
    UIGraphicsBeginImageContextWithOptions(size, GTrue, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:1 green:1 blue:1 alpha:1].CGColor);
    CGContextFillRect(context, rect);
//    [dateTime drawInRect:rect withAttributes:attr];
    [dateTime drawAtPoint:fontPoint withAttributes:attr];
//    [_timeLab drawViewHierarchyInRect:_timeLab.bounds afterScreenUpdates:NO];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}



-(void)livePush:(GJLivePush *)livePush connentSuccessWithElapsed:(GLong)elapsed{
    _pushStateLab.text = [NSString stringWithFormat:@"推流连接耗时：%ld ms",elapsed];
}
-(void)livePush:(GJLivePush *)livePush closeConnent:(GJPushSessionInfo *)info resion:(GJConnentCloceReason)reason{
    GJPushSessionInfo pushInfo = *info;
    dispatch_async(dispatch_get_main_queue(), ^{
        _pushStateLab.text = [NSString stringWithFormat:@"推流关闭,推流时长：%ld ms",pushInfo.sessionDuring];
    });
}


-(void)livePush:(GJLivePush *)livePush dynamicVideoUpdate:(VideoDynamicInfo *)elapsed{
    if (elapsed->currentBitrate/1024.0/8 > 1000) {
        NSLog(@"error");
    }
    _currentV.text = [NSString stringWithFormat:@"encode V b:%0.2fkB/s f:%0.2f",elapsed->currentBitrate/1024.0/8.0,elapsed->currentFPS];
}
-(void)livePush:(GJLivePush *)livePush errorType:(GJLiveErrorType)type infoDesc:(id)infoDesc{
    switch (type) {
        case kLivePushConnectError:{
            dispatch_async(dispatch_get_main_queue(), ^{
                _pushStateLab.text =@"推流连接失败";
            });
        }
        case kLivePushWritePacketError:{
            dispatch_async(dispatch_get_main_queue(), ^{
                _pushStateLab.text =@"尝试重连中";
            });
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [_livePush stopStreamPush];
                if (_pushStartBtn.selected) {
                    if(![_livePush startStreamPushWithUrl:_pushAddr]){
                        NSLog(@"startStreamPushWithUrl error");
                    };
                }
            });

            break;
        }
        default:
            break;
    }
}
//-(void)livePush:(GJLivePush *)livePush pushPacket:(R_GJH264Packet *)packet{
//    if (_pulls.count>0) {
//        GJStreamPacket ppush;
//        ppush.type = GJMediaType_Video;
//        ppush.packet.h264Packet = packet;
//        [_pulls[0].pull pullDataCallback:ppush];
//    }
//}
//-(void)livePush:(GJLivePush *)livePush pushImagebuffer:(CVImageBufferRef)packet pts:(CMTime)pts{
//    if (_pulls.count>0) {
//        [_pulls[0].pull pullimage:packet time:pts];
//
//    }
//
//}
-(void)livePush:(GJLivePush *)livePush recodeFinish:(NSError *)error{
    _uiRecode.enabled = YES;
    if (error) {
        NSLog(@"RECODE ERROR:%@",error);
    }else{
        NSLog(@"recode success");
    }
}
-(void)livePush:(GJLivePush *)livePush mixFileFinish:(NSString *)path{
    
    _audioMixBtn.selected = NO;
}

-(void)livePush:(GJLivePush *)livePush updatePushStatus:(GJPushSessionStatus *)status{
    _vSendRateLab.text = [NSString stringWithFormat:@"V BPS P:%0.2f E:%0.2f",status->videoStatus.pushBitrate/1024.0,status->videoStatus.encodeBitrate/1024.0];
    _aSendRateLab.text = [NSString stringWithFormat:@"A BPS P:%0.2f E:%0.2f",status->audioStatus.pushBitrate/1024.0,status->audioStatus.encodeBitrate/1024.0];

    _fpsLab.text = [NSString stringWithFormat:@"FPS V:%0.2f,A:%0.2f",status->videoStatus.frameRate,status->audioStatus.frameRate];
    _delayVLab.text = [NSString stringWithFormat:@"cache V t:%ld ms f:%ld",status->videoStatus.cacheTime,status->videoStatus.cacheCount];
    _delayALab.text = [NSString stringWithFormat:@"cache A t:%ld ms f:%ld",status->audioStatus.cacheTime,status->audioStatus.cacheCount];
}

@end

#define PULL_COUNT 1
@interface PullManager : NSObject<GJLivePullDelegate>
{
    NSMutableArray<UIView*>* _viewArr;
    NSInteger _bufferTimes;
    NSInteger _dewaterTimes;
    UITapGestureRecognizer* _tapGesture;
}
@property (copy, nonatomic) NSString    *pullAddr;
@property (strong, nonatomic) UILabel    *pullRateLab;
@property (strong, nonatomic) UILabel    *pullStateLab;
@property (strong, nonatomic) UILabel    *videoCacheLab;
@property (strong, nonatomic) UILabel    *audioCacheLab;
@property (strong, nonatomic) UILabel    *playerBufferLab;
@property (strong, nonatomic) UILabel    *netDelay;
@property (strong, nonatomic) UILabel    *shakeRange;
@property (strong, nonatomic) UILabel    *netShake;
@property (strong, nonatomic) UILabel    *testNetShake;
@property (strong, nonatomic) UILabel    *dewaterStatus;
@property (strong, nonatomic) UIView     * view;;
@property (strong, nonatomic) GJLivePull * pull;
@property (strong, nonatomic  ) UIButton   * pullBtn;;
@property (assign, nonatomic) CGRect     frame;
@property (assign, nonatomic) CGRect     beforeFullFrame;
@property (assign, nonatomic) BOOL       fullEnable;
@property (strong, nonatomic  ) UIView   * tipContentView;;

@end

@implementation PullManager
-(void)fullTap:(UITapGestureRecognizer*)tap{
    [UIView animateWithDuration:0.4 animations:^{
        if(!CGRectEqualToRect(_frame, [UIScreen mainScreen].bounds)){
            _beforeFullFrame = _frame;
            self.frame = [UIScreen mainScreen].bounds;
        }else{
            self.frame = _beforeFullFrame;
        }
        [_view.superview bringSubviewToFront:_view];
    }];
}
- (instancetype)initWithPullUrl:(NSString*)pullUrl;
{
    self = [super init];
    if (self) {
        _pullAddr = pullUrl;
        _pull = [[GJLivePull alloc]init];
        _pull.delegate = self;
        _viewArr = [NSMutableArray array];
        [self buildUI];
        self.fullEnable = YES;
    }
    return self;
}
-(void)setFullEnable:(BOOL)fullEnable{
    _tapGesture.enabled = fullEnable;
}

-(void)buildUI{
    _view = [[UIView alloc]init];
    [_view addSubview:[_pull getPreviewView]];
    _tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(fullTap:)];
    _tapGesture.numberOfTouchesRequired = 2;
    [_view addGestureRecognizer:_tapGesture];
    _pullBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _pullBtn.layer.borderWidth = 1;
    _pullBtn.layer.borderColor = [UIColor blackColor].CGColor;
    [_pullBtn setTitle:@"拉流1开始" forState:UIControlStateNormal];
    [_pullBtn setTitle:@"拉流1结束" forState:UIControlStateSelected];
    [_pullBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_pullBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_pullBtn addTarget:self action:@selector(takeSelect:) forControlEvents:UIControlEventTouchUpInside];
    _pullBtn.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:_pullBtn];
    
    _tipContentView = [[UIView alloc]init];
    
#ifdef PULL_TIP_SHOW
    [self.view addSubview:_tipContentView];
#endif
    
    _pullStateLab = [[UILabel alloc]init];
    _pullStateLab.numberOfLines = 0;
    _pullStateLab.text = @"未连接";
    _pullStateLab.textColor = [UIColor redColor];
    _pullStateLab.font = [UIFont systemFontOfSize:10];
    [_tipContentView addSubview:_pullStateLab];
    [_viewArr addObject:_pullStateLab];
    
    _pullRateLab = [[UILabel alloc]init];
    _pullRateLab.textColor = [UIColor redColor];
    _pullRateLab.text = @"Bitrate:0.0 KB/s";
    _pullRateLab.numberOfLines = 0;
    _pullRateLab.font = [UIFont systemFontOfSize:10];
    [_tipContentView addSubview:_pullRateLab];
    [_viewArr addObject:_pullRateLab];
    
    _videoCacheLab = [[UILabel alloc]init];
    _videoCacheLab.textColor = [UIColor redColor];
    _videoCacheLab.text = @"cache V:0.0 ms f:0";
    _videoCacheLab.numberOfLines = 0;
    _videoCacheLab.font = [UIFont systemFontOfSize:10];
    [_tipContentView addSubview:_videoCacheLab];
    [_viewArr addObject:_videoCacheLab];

    _audioCacheLab = [[UILabel alloc]init];
    _audioCacheLab.numberOfLines = 0;
    _audioCacheLab.textColor = [UIColor redColor];
    _audioCacheLab.text = @"cache A:0.0 ms f:0";
    _audioCacheLab.font = [UIFont systemFontOfSize:10];
    [_tipContentView addSubview:_audioCacheLab];
    [_viewArr addObject:_audioCacheLab];

    _netDelay = [[UILabel alloc]init];
    _netDelay.numberOfLines = 0;
    _netDelay.textColor = [UIColor redColor];
    _netDelay.text = @"NetDelay Measure:未工作";
    _netDelay.font = [UIFont systemFontOfSize:10];
    [_tipContentView addSubview:_netDelay];
    [_viewArr addObject:_netDelay];

    _testNetShake = [[UILabel alloc]init];
    _testNetShake.numberOfLines = 0;
    _testNetShake.textColor = [UIColor redColor];
    _testNetShake.text = @"Max netShake Measure:未工作";
    _testNetShake.font = [UIFont systemFontOfSize:10];
    [_tipContentView addSubview:_testNetShake];
    [_viewArr addObject:_testNetShake];

    _shakeRange = [[UILabel alloc]init];
    _shakeRange.numberOfLines = 0;
    _shakeRange.textColor = [UIColor redColor];
    _shakeRange.text = @"shake collect duration:0";
    _shakeRange.font = [UIFont systemFontOfSize:10];
    [_tipContentView addSubview:_shakeRange];
    [_viewArr addObject:_shakeRange];

    _netShake = [[UILabel alloc]init];
    _netShake.numberOfLines = 0;
    _netShake.textColor = [UIColor redColor];
    _netShake.text = @"Max netShake:0 ms";
    _netShake.font = [UIFont systemFontOfSize:10];
    [_tipContentView addSubview:_netShake];
    [_viewArr addObject:_netShake];

    _dewaterStatus = [[UILabel alloc]init];
    _dewaterStatus.numberOfLines = 0;
    _dewaterStatus.textColor = [UIColor redColor];
    _dewaterStatus.text = @"dewaterStatus:false times:0";
    _dewaterStatus.font = [UIFont systemFontOfSize:10];
    [_tipContentView addSubview:_dewaterStatus];
    [_viewArr addObject:_dewaterStatus];

    _playerBufferLab = [[UILabel alloc]init];
    _playerBufferLab.numberOfLines = 0;
    _playerBufferLab.textColor = [UIColor redColor];
    _playerBufferLab.text = @"buffer：0 times:0";
    _playerBufferLab.font = [UIFont systemFontOfSize:10];
    [_tipContentView addSubview:_playerBufferLab];
    [_viewArr addObject:_playerBufferLab];

}
-(void)setFrame:(CGRect)frame{
    _frame = frame;
    self.view.frame = frame;
    
    CGRect rect = self.view.bounds;
    rect.size.height = 30;
    _pullBtn.frame = rect;
    rect.origin.x = 0;
    rect.origin.y = CGRectGetMaxY(rect);
    rect.size.height = frame.size.height - rect.origin.y;
    
    _pull.previewView.frame = rect;
    
    rect.origin.y -= _pullBtn.frame.size.height;
    _tipContentView.frame = rect;
    
    rect.size.height *= 1.0/_viewArr.count;
    rect.origin.y = 0;

    for (int i = 0; i<_viewArr.count; i++) {
        UIView* view = _viewArr[i];
        rect.origin.y += rect.size.height;
        view.frame = rect;
    }
}

-(void)takeSelect:(UIButton*)btn{
    btn.selected = !btn.selected;
    if (btn.selected) {
        _pullStateLab.text = @"连接中";
        _dewaterTimes = _bufferTimes = 0;
        _dewaterStatus.text = [NSString stringWithFormat:@"dewaterStatus:false times:0"];
        _playerBufferLab.text = [NSString stringWithFormat:@"buffer：0 times:0"];

        if(![_pull startStreamPullWithUrl:_pullAddr]){
            btn.selected = NO;
        };
    }else{
        [_pull stopStreamPull];
        _pullStateLab.text = @"结束连接";
    }
}

-(void)livePull:(GJLivePull *)livePull connentSuccessWithElapsed:(int)elapsed{
    dispatch_async(dispatch_get_main_queue(), ^{
        _pullStateLab.text = [NSString stringWithFormat:@"connent during：%d ms",elapsed];
    });
    
}
-(void)livePull:(GJLivePull *)livePull closeConnent:(GJPullSessionInfo *)info resion:(GJConnentCloceReason)reason{
    GJPullSessionInfo sInfo= *info;
    dispatch_async(dispatch_get_main_queue(), ^{
        _pullStateLab.text = [NSString stringWithFormat:@"connent total：%ld ms",sInfo.sessionDuring];
    });
}
-(void)livePull:(GJLivePull *)livePull updatePullStatus:(GJPullSessionStatus *)status{
    GJPullSessionStatus pullStatus = *status;
    dispatch_async(dispatch_get_main_queue(), ^{
        _pullRateLab.text = [NSString stringWithFormat:@"bitrate V:%0.2f A:%0.2f",pullStatus.videoStatus.bitrate/1024.0,pullStatus.audioStatus.bitrate/1024.0];
        _videoCacheLab.text = [NSString stringWithFormat:@"cache V t:%ld ms f:%ld",pullStatus.videoStatus.cacheTime,pullStatus.videoStatus.cacheCount];
        _audioCacheLab.text = [NSString stringWithFormat:@"cache A t:%ld ms f:%ld",pullStatus.audioStatus.cacheTime,pullStatus.audioStatus.cacheCount];
    });
}

-(void)livePull:(GJLivePull *)livePull netShakeUpdate:(long)shake{
    dispatch_async(dispatch_get_main_queue(), ^{
        _netShake.text = [NSString stringWithFormat:@"Max netShake:%ld ms",shake];
    });
}
-(void)livePull:(GJLivePull *)livePull netShakeRangeUpdate:(long)shake{
    dispatch_async(dispatch_get_main_queue(), ^{
        _shakeRange.text = [NSString stringWithFormat:@"shake collect delay:%ld ms",shake];
    });
}

-(void)livePull:(GJLivePull *)livePull testNetShake:(long)shake{
    dispatch_async(dispatch_get_main_queue(), ^{
        _testNetShake.text = [NSString stringWithFormat:@"Max NetShake Measure:%ld ms",shake];
    });
}

-(void)livePull:(GJLivePull *)livePull dewaterUpdate:(BOOL)isDewatering{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isDewatering) {
            _dewaterTimes++;
            _dewaterStatus.text = [NSString stringWithFormat:@"dewaterStatus:true times:%ld",(long)_dewaterTimes];
        }else{
            _dewaterStatus.text = [NSString stringWithFormat:@"dewaterStatus:false times:%ld",(long)_dewaterTimes];
        }
    });
}
-(void)livePull:(GJLivePull *)livePull firstFrameDecode:(GJPullFirstFrameInfo *)info{
    NSLog(@"firstFrameDecode w:%f,h:%f delay:%ld ts:%ld",info->size.width,info->size.height,info->delay,(long)[[NSDate date]timeIntervalSince1970]*1000);
    
}

-(void)livePull:(GJLivePull *)livePull firstFrameRender:(GJPullFirstFrameInfo *)info{
    GLong delay = info->delay;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _pullStateLab.text = [NSString stringWithFormat:@"%@,first render delay:%ld ms",_pullStateLab.text,delay];

    });
    NSLog(@"firstFrameRender w:%f,h:%f delay:%ld ts:%ld",info->size.width,info->size.height,info->delay,(long)[[NSDate date]timeIntervalSince1970]*1000);
}

-(void)livePull:(GJLivePull *)livePull errorType:(GJLiveErrorType)type infoDesc:(NSString *)infoDesc{
    switch (type) {
        case kLivePullReadPacketError:
        case kLivePullConnectError:{
            [livePull stopStreamPull];
            sleep(1);
            dispatch_async(dispatch_get_main_queue(), ^{
                if(_pullBtn.selected){
                    _pullStateLab.text = @"尝试重连中";
                    [livePull startStreamPullWithUrl:_pullAddr];
                }
            });
            break;
        }
        default:
            break;
    }
}

-(void)livePull:(GJLivePull *)livePull bufferUpdatePercent:(float)percent duration:(long)duration{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (duration == 0.0) {
            _bufferTimes ++;
        }
        _playerBufferLab.text = [NSString stringWithFormat:@"buffer：%0.2f %ld ms times:%ld",percent,duration,(long)_bufferTimes];
    });
}

-(void)livePull:(GJLivePull *)livePull networkDelay:(long)delay{
    dispatch_async(dispatch_get_main_queue(), ^{
        _netDelay.text = [NSString stringWithFormat:@"Avg display delay Measure:%ld ms",delay];
    });
}


@end
@interface GJLivePushViewController ()
{
    PushManager* _pushManager;
    
}
@property (strong, nonatomic) UIView *bottomView;
@property(strong,nonatomic)NSMutableArray<PullManager*>* pulls;

@end

@implementation GJLivePushViewController


-(void)barItemTap:(UIBarButtonItem*)item{
    if (item == self.navigationItem.leftBarButtonItem) {
        [self.navigationController popViewControllerAnimated:YES];
    }else if(item == self.navigationItem.rightBarButtonItem){
        
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"直播间";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(barItemTap:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(barItemTap:)];
    _pulls = [[NSMutableArray alloc]initWithCapacity:2];
    GJ_LogSetLevel(GJ_LOGDEBUG);
    NSString* path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true)[0];
    path = [path stringByAppendingPathComponent:@"live.log"];
#ifndef DEBUG
    GJ_LogSetOutput(path.UTF8String);
#endif

    if(_type == kGJCaptureTypeAR){
        if( [UIDevice currentDevice].systemVersion.doubleValue < 11.0 || !ARConfiguration.isSupported){
            [[[UIAlertView alloc]initWithTitle:@"提示" message:@"该手机不支持ar,已切换到普通直播" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles: nil] show];
            _type = kGJCaptureTypeCamera;
        }
    }
    if(_pushAddr.length > 3)_pushManager = [[PushManager alloc]initWithPushUrl:_pushAddr type:_type];
    //ui放在后面，因为ar一定要先设置ARScene
    [self buildUI];
    [self updateFrame];
    switch (_type) {
        case kGJCaptureTypeView:{
            _pushManager.livePush.captureView = _pulls[0].view;
            break;
        }
        case kGJCaptureTypePaint:{
            break;
        }
        case kGJCaptureTypeAR:
        {
            _pushManager.livePush.ARScene = [[GJSunSystemARScene alloc]init];
            break;
        }

        default:
            break;
    }
    
    if(_pushManager){
        [_pushManager.livePush startPreview];
    }else{
        for (PullManager* pull in _pulls) {
            [pull takeSelect:pull.pullBtn];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [_pushManager.livePush stopPreview];
        [_pushManager.livePush stopStreamPush];
        _pushManager = nil;
        
        for (PullManager* pull in _pulls) {
            [pull.pull stopStreamPull];
        }
        [_pulls removeAllObjects];
        
        cleanMemory(GTrue);
        NSLog(@"clean over");
    });
}

-(void)buildUI{
    if (_pushAddr.length > 3)[self.view addSubview:_pushManager.view];
    
    if (_pullAddr.length > 3) {
        for (int i = 0; i<PULL_COUNT; i++) {
            PullManager* pullManager = [[PullManager alloc]initWithPullUrl:_pullAddr];
            pullManager.fullEnable = _pushAddr.length > 3;
            pullManager.view.backgroundColor = [UIColor colorWithRed:(arc4random()%200 + 50)/255.0 green:(arc4random()%200 + 50)/255.0 blue:(arc4random()%200 + 50)/255.0 alpha:1.0];
            pullManager.pullBtn.backgroundColor = pullManager.view.backgroundColor;
            [_pulls addObject:pullManager];
            [self.view addSubview:pullManager.view];
        }
    }
}
//-(UIImage*)backImageWithSize:(CGSize)size color:(UIColor*)color{
//    UIGraphicsBeginImageContext(size);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetStrokeColorWithColor(context, color.CGColor);
//    CGContextSetLineWidth(context, 6);
//    CGFloat border = 5;
//    CGFloat width = size.height * 0.5 - border;
//    CGContextMoveToPoint(context, border, width + border);
//    CGContextAddLineToPoint(context, width*0.5 + border, border);
//
//    CGContextMoveToPoint(context, border, width + border);
//    CGContextAddLineToPoint(context, width*0.5 + border, 2 * width + border);
//
//    CGContextMoveToPoint(context, border, width + border);
//    CGContextAddLineToPoint(context, size.width - border, width  + border);
//
//    CGContextStrokePath(context);
//    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return image;
//}


-(void)updateFrame{
    CGRect rect = self.view.bounds;
    if (_pushAddr.length > 3) {
        if (_pullAddr.length > 3) {
            rect.size.height *= 0.5;
        }
        _pushManager.frame = rect;
    }else{
        rect.size.height = self.navigationController.navigationBar.bounds.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    }

    if (_pullAddr.length > 3) {
        CGRect sRect;
        sRect.origin.x = 0;
        sRect.origin.y = CGRectGetMaxY(rect);
        sRect.size.height = self.view.bounds.size.height - sRect.origin.y;
        sRect.size.width = self.view.bounds.size.width/PULL_COUNT;
        for (int i = 0; i<PULL_COUNT; i++) {
            rect.origin.x = CGRectGetMaxX(rect);
            PullManager* show = _pulls[i];
            show.frame = sRect;
            sRect.origin.x = CGRectGetMaxX(sRect);
        }
    }

}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    GJInterfaceOrientation orientation = kGJInterfaceOrientationUnknown;
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
            orientation = kGJInterfaceOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            orientation = kGJInterfaceOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            orientation = kGJInterfaceOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            orientation = kGJInterfaceOrientationLandscapeRight;
            break;
        default:
            break;
    }
    [UIView animateWithDuration:0.4 animations:^{
        [self updateFrame];
        _pushManager.livePush.outOrientation = orientation;
    }];
    NSLog(@"didRotateFromInterfaceOrientation");
    
}


//static void ReleaseCVPixelBuffer(void *pixel, const void *data, size_t size)
//{
//    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)pixel;
//    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
//    CVPixelBufferRelease( pixelBuffer );
//}
//static OSStatus CreateCGImageFromCVPixelBuffer(CVPixelBufferRef pixelBuffer, CGImageRef *imageOut)
//{
//    OSStatus err = noErr;
//    OSType sourcePixelFormat;
//    size_t width, height, sourceRowBytes;
//    void *sourceBaseAddr = NULL;
//    CGBitmapInfo bitmapInfo;
//    CGColorSpaceRef colorspace = NULL;
//    CGDataProviderRef provider = NULL;
//    CGImageRef image = NULL;
//    sourcePixelFormat = CVPixelBufferGetPixelFormatType( pixelBuffer );
//    if ( kCVPixelFormatType_32ARGB == sourcePixelFormat )
//        bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipFirst;
//    else if ( kCVPixelFormatType_32BGRA == sourcePixelFormat )
//        bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
//    else
//        return -95014; // only uncompressed pixel formats
//    sourceRowBytes = CVPixelBufferGetBytesPerRow( pixelBuffer );
//    width = CVPixelBufferGetWidth( pixelBuffer );
//    height = CVPixelBufferGetHeight( pixelBuffer );
//    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
//    sourceBaseAddr = CVPixelBufferGetBaseAddress( pixelBuffer );
//    colorspace = CGColorSpaceCreateDeviceRGB();
//    CVPixelBufferRetain( pixelBuffer );
//    provider = CGDataProviderCreateWithData( (void *)pixelBuffer, sourceBaseAddr, sourceRowBytes * height, ReleaseCVPixelBuffer);
//    image = CGImageCreate(width, height, 8, 32, sourceRowBytes, colorspace, bitmapInfo, provider, NULL, true, kCGRenderingIntentDefault);
//    if ( err && image ) {
//        CGImageRelease( image );
//        image = NULL;
//    }
//    if ( provider ) CGDataProviderRelease( provider );
//    if ( colorspace ) CGColorSpaceRelease( colorspace );
//    *imageOut = image;
//    return err;
//}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(PullManager*)getShowWithPush:(GJLivePull*)pull{
    for (PullManager* show in _pulls) {
        if (show.pull == pull) {
            return show;
        }
    }
    return 0;
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"是否测试释放推拉流对象" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
    //    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        _pushManager = nil;
        [_pulls removeAllObjects];
        NSLog(@"释放完成");
        cleanMemory(GFalse);
    }
}

-(void)dealloc{
    
    NSLog(@"dealloc:%@",self);
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

