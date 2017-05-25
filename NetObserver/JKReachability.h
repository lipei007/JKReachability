//
//  JKReachability.h
//  JKReachability
//
//  Created by emerys on 2016/11/9.
//  Copyright © 2016年 Emerys. All rights reserved.
//

#import <Foundation/Foundation.h>

#define Default_Check_Interval 1

extern NSString *kNetworkStatusChangeNotification;
extern NSString *kNetworkStatusInitialNotification;

typedef NS_ENUM(NSInteger, ReachabilityStatus) {
    
    ReachabilityStatusUnknown = -1,
    ReachabilityStatusNotReachable = 0,
    ReachabilityStatusViaWWAN = 1,
    ReachabilityStatusViaWiFi = 2
};

typedef NS_ENUM(NSInteger, WWANAccessType) {
    WWANTypeUnknown = -1,
    WWANType2G = 2,
    WWANType3G = 3,
    WWANType4G = 4
};



@interface JKReachability : NSObject

@property (nonatomic,copy) NSString *host;///<ping host，default www.apple.com
@property (nonatomic,assign) NSTimeInterval timeout;///<超时时间，default 0.3
@property (nonatomic,assign) NSInteger resendCount;///<超时重发次数 default 3
@property (nonatomic,assign) float checkInterval;///<检查网络状态间隔时间 default 1 minute

@property (nonatomic,assign,readonly) ReachabilityStatus reachabilityStatus;
@property (nonatomic,assign,readonly) WWANAccessType wwanType;

+ (instancetype)sharedInstance;

- (void)startNotifier;
- (void)stopNotifier;


@end
