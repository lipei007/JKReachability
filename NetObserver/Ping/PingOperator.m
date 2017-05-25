//
//  PingOperator.m
//  JKReachability
//
//  Created by emerys on 2016/11/10.
//  Copyright © 2016年 Emerys. All rights reserved.
//

#import "PingOperator.h"
#import "SimplePing.h"

@interface PingOperator ()<SimplePingDelegate>
{
    BOOL _isPing;
    BOOL _isStop;
    SimplePing *_pinger;
    PingStatus _currentPingStatus;
}

@property (nonatomic,copy) void(^pingFinishBlock)(BOOL);


@end

@implementation PingOperator

static int sendPackageCount = 0;

#pragma mark - life

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.resendCount = Default_Resend_Count;
        self.timeout = Default_Timeout;
        self.host = kDefault_Host;
        _isPing = NO;
        _isStop = NO;
        _currentPingStatus = PingStatusUnKnown;
    }
    return self;
    
}

+ (instancetype)sharedInstance {
    
    static PingOperator *operator = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        operator = [[PingOperator alloc] init];
    });
    return operator;
    
}

- (void)setHost:(NSString *)host {
    _host = host;
    
    _pinger = [[SimplePing alloc] initWithHostName:host];
    _pinger.delegate = self;
}

- (PingStatus)currentPingStatus {
    return _currentPingStatus;
}

- (void)setPingStatus:(PingStatus)status {
    
    sendPackageCount = 0;
    
    if (status != PingStatusUnKnown) {
        
        _currentPingStatus = status;
        
    }
    
    if (status == PingStatusUnReachable) {
        if (self.pingFinishBlock) {
            self.pingFinishBlock(NO);
        }
    }
    
    if (status == PingStatusReachable) {
        if (self.pingFinishBlock) {
            self.pingFinishBlock(YES);
        }
    }
    
}

#pragma mark - action

- (void)pingFinishBlock:(void (^)(BOOL success))completion {
    
    self.pingFinishBlock = completion;
    
    if (!_isPing) {
        
        if ([[NSThread currentThread] isMainThread]) {
            
            [self startPing];
            
        } else {
            
            __weak typeof(self) weakself = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (weakself) {
                    __strong typeof(weakself) strongself = weakself;
                    [strongself startPing];
                }
                
            });
            
        }
        
    }
    
}

- (void)startPing {
    
    if (!_isPing) {
        
        _isPing = YES;
        [_pinger start];
        
        [self performSelector:@selector(pingTimeout) withObject:nil afterDelay:self.timeout];
    }
    
}

- (void)stopPing {
    if (_isPing) {
   
        _isPing = NO;
        [_pinger stop];
    
    }
}

- (void)resetPing {
    if (_isPing) {
        [self stopPing];
    }
    
    [self startPing];
}

- (void)invalidate {
    
    _isStop = YES;
    
    self.pingFinishBlock = nil;
    
    if (_isPing) {
        [self stopPing];
    }
    
}


#pragma mark - Ping Delegate

- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
    [_pinger sendPingWithData:nil];
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
//    NSLog(@"\nsend Packet:%@\nsequentNo.:%d",packet,sequenceNumber);
    sendPackageCount++;
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error {
//    NSLog(@"failed to send");
    [self stopPing];
    [self setPingStatus:PingStatusUnReachable];

}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
//    NSLog(@"receive data");
    [self stopPing];
    [self setPingStatus:PingStatusReachable];

}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet {
//    NSLog(@"receive unexpected");
    [self stopPing];
    [self setPingStatus:PingStatusUnReachable];

}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error {
//    NSLog(@"failed error:%@",error);
    [self stopPing];
    [self setPingStatus:PingStatusUnReachable];
    
}

#pragma mark - Time out

- (void)pingTimeout {
    
    if (_isStop) {
        return;
    }
    
    if (_isPing) {
        
        [self stopPing];
        
    }
    
    
    if (sendPackageCount < self.resendCount) { // 超时，重发
        
        
        
    } else { // 重发次数超出，ping不可达
        
        [self setPingStatus:PingStatusUnReachable];
    }
    
    [self startPing];
    
}


@end
