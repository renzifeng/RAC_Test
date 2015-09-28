//
//  RedView.m
//  RAC
//
//  Created by renzifeng on 15/9/28.
//  Copyright © 2015年 任子丰. All rights reserved.
//

#import "RedView.h"

@implementation RedView

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.login = !self.login;
}

@end
