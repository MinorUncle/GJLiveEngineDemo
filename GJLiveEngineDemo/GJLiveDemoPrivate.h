//
//  GJLiveDemoPrivate.h
//  GJLiveEngineDemo
//
//  Created by kyle on 2018/9/26.
//  Copyright © 2018年 MinorUncle. All rights reserved.
//

#ifndef GJLiveDemoPrivate_h
#define GJLiveDemoPrivate_h

#define PULL_URL @"rtmp://live.hkstv.hk.lxdns.com/live/hks";
#define RECODE_NET
#define PULL_COUNT 1

//请注释 #import "StreamAddr.h",自行通过以下宏配置推拉流地址。
#import "StreamAddr.h"
//#define PUSH_URL
//#define PULL_URL
//#undef PUSH_URL
//#define PULL_URL @"http://pull-flv-l6-spe.ixigua.com/fantasy/stream-6613909499315129091_720p.flv"
#endif /* GJLiveDemoPrivate_h */
