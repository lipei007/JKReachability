//
//  ViewController.m
//  JKReachability
//
//  Created by emerys on 2016/11/9.
//  Copyright © 2016年 Emerys. All rights reserved.
//

#import "ViewController.h"
#import "Reachability.h"
#import "PingOperator.h"
#import "JKReachability.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UILabel *show;

@end

@implementation ViewController

- (void) handleStatus {
    
    self.show.text = @"Unkonwn";
    
    switch ([JKReachability sharedInstance].reachabilityStatus) {
        case ReachabilityStatusNotReachable:{
            self.show.text = @"Not Reach";
        }
            break;
        case ReachabilityStatusViaWiFi: {
            self.show.text = @"WIFI";
        }
            break;
        case ReachabilityStatusViaWWAN: {
            
            switch ([JKReachability sharedInstance].wwanType) {
                case WWANType2G:{
                    self.show.text = @"2G";
                }
                    break;
                case WWANType3G: {
                    self.show.text = @"3G";
                }
                    break;
                case WWANType4G: {
                    self.show.text = @"4G";
                }
                    break;
                    
                default:
                    break;
            }
            
        }
            break;

    
        default:
            break;
    }
}

- (void)startNotify:(NSNotification *)not {
    [self handleStatus];
}

- (void)changeStatus:(NSNotification *)not {
    [self handleStatus];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startNotify:) name:kNetworkStatusInitialNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeStatus:) name:kNetworkStatusChangeNotification object:nil];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    
//    [PingOperator sharedInstance].host = @"www.hao268.com";
//    [[PingOperator sharedInstance] pingFinishBlock:^(BOOL success){
//        
//        if (success) {
//            NSLog(@"ping reachable");
//        } else {
//            NSLog(@"ping not reachable");
//        }
//        
//    }];
//    
//    [[PingOperator sharedInstance] resetPing];
//    
//    
//    [[JKReachability sharedInstance] startNotifier];
    
    [[JKReachability sharedInstance] startNotifier];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
