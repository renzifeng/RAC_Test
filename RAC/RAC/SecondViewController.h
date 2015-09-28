//
//  SecondViewController.h
//  RAC
//
//  Created by renzifeng on 15/9/28.
//  Copyright © 2015年 任子丰. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface SecondViewController : UIViewController
@property (nonatomic, strong) RACSubject *delegateSignal;
@end
