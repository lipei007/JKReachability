/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 */

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <netinet/in.h>

#import <CoreFoundation/CoreFoundation.h>

#import "Reachability.h"

#pragma mark IPv6 Support
//Reachability fully support IPv6.  For full details, see ReadMe.md.


NSString *kReachabilityChangedNotification = @"kNetworkReachabilityChangedNotification";
NSString *kReachabilityInitialNotification = @"kNetworkReachabilityInitialNotification";

#pragma mark - Supporting functions

#define kShouldPrintReachabilityFlags 1

static void PrintReachabilityFlags(SCNetworkReachabilityFlags flags, const char* comment)
{
#if kShouldPrintReachabilityFlags

    NSLog(@"Reachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n",
          (flags & kSCNetworkReachabilityFlagsIsWWAN)				? 'W' : '-',
          (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',

          (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
          (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
          (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
          (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-',
          comment
          );
#endif
}


static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
#pragma unused (target, flags)

    Reachability* noteObject = (__bridge Reachability *)info;
    // Post a notification to notify the client that the network reachability changed.
    [[NSNotificationCenter defaultCenter] postNotificationName: kReachabilityChangedNotification object: noteObject];
}


#pragma mark - Reachability implementation

@implementation Reachability
{
	SCNetworkReachabilityRef _reachabilityRef; // 创建测试连接返回的引用
    dispatch_queue_t         _reachabilitySerialQueue;
}

- (instancetype)init {
    if (self = [super init]) {
        
        struct sockaddr_in address;
        bzero(&address, sizeof(address));
        address.sin_len = sizeof(address);
        address.sin_family = AF_INET;
        // 根据传入的地址测试连接,0.0.0.0时则可以查询本机的网络连接状态。
        _reachabilityRef = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *) &address);
        
        _reachabilitySerialQueue = dispatch_queue_create("com.jack.connection", NULL);
        
    }
    return self;
}

+ (instancetype) sharedInstance {
    static Reachability *connection = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        
        connection = [[Reachability alloc] init];
        
    });
    return connection;
}

- (void)dealloc
{
    [self stopNotifier];
    if (_reachabilityRef != NULL)
    {
        CFRelease(_reachabilityRef);
    }
    _reachabilitySerialQueue = NULL;
}

#pragma mark - Start and stop notifier

- (BOOL)startNotifier
{
	BOOL returnValue = NO;
	SCNetworkReachabilityContext context = {0, NULL, NULL, NULL, NULL};

	if (SCNetworkReachabilitySetCallback(_reachabilityRef, ReachabilityCallback, &context))
	{
		if (SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, _reachabilitySerialQueue))
		{
			returnValue = YES;
            
        } else {
            SCNetworkReachabilitySetCallback(_reachabilityRef, NULL, NULL);
        }
    } else {
        
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityInitialNotification object:nil];
        
    });
    
	return returnValue;
}


- (void)stopNotifier
{
	if (_reachabilityRef != NULL)
	{
		SCNetworkReachabilitySetCallback(_reachabilityRef, NULL, NULL);
        SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, NULL);
	}
}


#pragma mark - Network Flag Handling

- (NetworkStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags
{
	
	if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
	{
		// The target host is not reachable.
		return NotReachable;
	}

    NetworkStatus returnValue = NotReachable;

	if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
	{
		/*
         If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
         */
		returnValue = ReachableViaWiFi;
	}

	if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
        (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
	{
        /*
         ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
         */

        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
        {
            /*
             ... and no [user] intervention is needed...
             */
            returnValue = ReachableViaWiFi;
        }
    }

	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
	{
		/*
         ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
         */
		returnValue = ReachableViaWWAN;
	}
    
	return returnValue;
}


- (NetworkStatus)currentReachabilityStatus
{
	NSAssert(_reachabilityRef != NULL, @"currentNetworkStatus called with NULL SCNetworkReachabilityRef");
	NetworkStatus returnValue = NotReachable;
	SCNetworkReachabilityFlags flags;
    
	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags))
	{
        returnValue = [self networkStatusForFlags:flags];
	}
    
	return returnValue;
}

#pragma mark - status

- (BOOL)isReachable {
    SCNetworkReachabilityFlags flag;
    if (!SCNetworkReachabilityGetFlags(_reachabilityRef, &flag)) {
        return NO;
    } else {
        if ([self networkStatusForFlags:flag] == NotReachable) {
            return NO;
        }
    }
    return YES;
}

- (NetworkStatus)currentStatus {
    if (self.isReachable) {
        return [self currentReachabilityStatus];
    }
    return NotReachable;
}


- (SCNetworkReachabilityFlags)currentReachabilityFlags {
    
    SCNetworkReachabilityFlags flags = 0;
    
    // 获得测试连接的状态，第一参数为之前建立的测试连接引用，第二参数用来保存获得的状态，如果获得状态则返回TRUE, 否则返回FALSE
    SCNetworkReachabilityGetFlags(_reachabilityRef, &flags);
    
    return flags;
}



@end
