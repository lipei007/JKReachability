//
//  PingOperator.h
//  JKReachability
//
//  Created by emerys on 2016/11/10.
//  Copyright © 2016年 Emerys. All rights reserved.
//

#import <Foundation/Foundation.h>


#define kDefault_Host @"www.apple.com"
#define Default_Timeout 0.3
#define Default_Resend_Count 3

typedef NS_ENUM(NSInteger,PingStatus){
    PingStatusUnKnown = -1,
    PingStatusUnReachable = 0,
    PingStatusReachable
};

@interface PingOperator : NSObject

@property (nonatomic,copy) NSString *host;///<ping host，default www.apple.com
@property (nonatomic,assign) NSTimeInterval timeout;///<超时时间，default 0.3
@property (nonatomic,assign) NSInteger resendCount;///<超时重发次数 default 3

@property (nonatomic,assign,readonly) PingStatus currentPingStatus;

+ (instancetype)sharedInstance;

- (void)pingFinishBlock:(void(^)(BOOL success))completion;

- (void)resetPing;

- (void)invalidate;

@end
