//
//  JKReachability.m
//  JKReachability
//
//  Created by emerys on 2016/11/9.
//  Copyright © 2016年 Emerys. All rights reserved.
//

#import "JKReachability.h"
#import "Reachability.h"
#import "PingOperator.h"
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>




NSString *kNetworkStatusChangeNotification = @"kNetworkStatusChangeNotification";
NSString *kNetworkStatusInitialNotification = @"kNetworkStatusInitialNotification";

@interface JKReachability ()
{
    ReachabilityStatus _currentReachabilityStatus;
    BOOL _reachable;
}

@property (nonatomic,assign,getter=isNotifying) BOOL notifying;

@property (nonatomic,strong) NSArray *type2GStrings;
@property (nonatomic,strong) NSArray *type3GStrings;
@property (nonatomic,strong) NSArray *type4GStrings;


@end


@implementation JKReachability

- (NSArray *)type2GStrings {
    if (!_type2GStrings) {
        _type2GStrings = @[CTRadioAccessTechnologyEdge,
                           CTRadioAccessTechnologyGPRS,
                           CTRadioAccessTechnologyCDMA1x];
    }
    return _type2GStrings;
}

- (NSArray *)type3GStrings {
    if (!_type3GStrings) {
        _type3GStrings = @[CTRadioAccessTechnologyHSDPA,
                          CTRadioAccessTechnologyWCDMA,
                          CTRadioAccessTechnologyHSUPA,
                          CTRadioAccessTechnologyCDMAEVDORev0,
                          CTRadioAccessTechnologyCDMAEVDORevA,
                          CTRadioAccessTechnologyCDMAEVDORevB,
                          CTRadioAccessTechnologyeHRPD];
    }
    return _type3GStrings;
}

- (NSArray *)type4GStrings {
    if (!_type4GStrings) {
        _type4GStrings = @[CTRadioAccessTechnologyLTE];
    }
    return _type4GStrings;
}

#pragma mark - life

- (void)dealloc {
    if (self.isNotifying) {
        [self stopNotifier];
    }
}

- (instancetype)init {
    if (self = [super init]) {
        
        _currentReachabilityStatus = ReachabilityStatusUnknown;
        
    }
    return self;
}

+ (instancetype)sharedInstance {
    static JKReachability *reachability = nil;
    static dispatch_once_t token;
    _dispatch_once(&token, ^{
        reachability = [[JKReachability alloc] init];
        reachability.host = kDefault_Host;
        reachability.timeout = Default_Timeout;
        reachability.resendCount = Default_Resend_Count;
        reachability.checkInterval = Default_Check_Interval;
    });
    
    return reachability;
}

- (WWANAccessType)accessTypeForString:(NSString *)accessString
{
    if ([self.type4GStrings containsObject:accessString])
    {
        return WWANType4G;
    }
    else if ([self.type3GStrings containsObject:accessString])
    {
        return WWANType3G;
    }
    else if ([self.type2GStrings containsObject:accessString])
    {
        return WWANType2G;
    }
    else
    {
        return WWANTypeUnknown;
    }
}

- (ReachabilityStatus)reachabilityStatus {
    return _currentReachabilityStatus;
}

- (WWANAccessType)wwanType {
    
    if (self.reachabilityStatus != ReachabilityStatusViaWWAN) {
        return WWANTypeUnknown;
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        CTTelephonyNetworkInfo *teleInfo= [[CTTelephonyNetworkInfo alloc] init];
        NSString *accessString = teleInfo.currentRadioAccessTechnology;
        if ([accessString length] > 0)
        {
            return [self accessTypeForString:accessString];
        }
        else
        {
            return WWANTypeUnknown;
        }
    }
    else
    {
        return WWANTypeUnknown;
    }

    
}


#pragma mark - set

- (void)setHost:(NSString *)host {
    _host = host;
    [PingOperator sharedInstance].host = host;
//    [[PingOperator sharedInstance] resetPing];
}

- (void)setTimeout:(NSTimeInterval)timeout {
    _timeout = timeout;
    [PingOperator sharedInstance].timeout = timeout;
}

- (void)setResendCount:(NSInteger)resendCount {
    _resendCount = resendCount;
    [PingOperator sharedInstance].resendCount = resendCount;
}

#pragma mark - notifier

- (void)startNotifier {
    if (self.isNotifying) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initialReachabilityNotification:) name:kReachabilityInitialNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changedReachabilityNotification:) name:kReachabilityChangedNotification object:nil];
    
    [[Reachability sharedInstance] startNotifier];
    
    _notifying = YES;
}

- (void)stopNotifier {
    if (!self.isNotifying) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityInitialNotification object:nil];
    
    [[Reachability sharedInstance] stopNotifier];
    [[PingOperator sharedInstance] invalidate];
    
    _notifying = NO;
}

#pragma mark - Block

- (void)networkChangeBlock:(void(^)(ReachabilityStatus status)) handler {
     NetworkStatus status = [Reachability sharedInstance].currentStatus;
    if (status == NotReachable) {
        if (handler) {
            handler(ReachabilityStatusNotReachable);
        }
        return;
    }
    
    
    
}

#pragma mark - Reachabligity Notification Handler

- (void)anasysNetworkStatus:(NetworkStatus)status ping:(BOOL)ping{
    
    ReachabilityStatus preStatus = _currentReachabilityStatus;
    
    switch (status) {
        case NotReachable: {

            _currentReachabilityStatus = ReachabilityStatusNotReachable;
        }
            break;
        case  ReachableViaWiFi: {

            _currentReachabilityStatus = ping ? ReachabilityStatusViaWiFi : ReachabilityStatusNotReachable;
        }
            break;
        case ReachableViaWWAN: {
            
            _currentReachabilityStatus = ping ? ReachabilityStatusViaWWAN : ReachabilityStatusNotReachable;
        }
            break;
            
        default:
            break;
    }
    
    if (preStatus == ReachabilityStatusUnknown) { // 初始化
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetworkStatusInitialNotification object:nil];
    }
    
    if (preStatus != _currentReachabilityStatus) { // 网络状态改变
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetworkStatusChangeNotification object:nil];
    }
    
}

- (void)pingReachabilityStatus:(NetworkStatus)status {
    
    __weak typeof(self) weakself = self;
    
    [[PingOperator sharedInstance] pingFinishBlock:^(BOOL success){
        
        [weakself anasysNetworkStatus:status ping:success];
        
    }];
    
    [[PingOperator sharedInstance] resetPing];
    
}

- (void)initialReachabilityNotification:(NSNotification *)notification {
   
    [self pingReachabilityStatus:[Reachability sharedInstance].currentStatus];

    
}

- (void)changedReachabilityNotification:(NSNotification *)notification {
    
    [self pingReachabilityStatus:[Reachability sharedInstance].currentStatus];
    
}

@end
