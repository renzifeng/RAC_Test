//
//  ViewController.m
//  RAC
//
//  Created by renzifeng on 15/9/28.
//  Copyright © 2015年 任子丰. All rights reserved.
//

#import "ViewController.h"
#import "RedView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/EXTScope.h>
#import "SecondViewController.h"
#import "EXTScope.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet RedView *redView;
@property (weak, nonatomic) IBOutlet UIButton *redBtn;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITextField *userTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (nonatomic, assign) BOOL isLogin;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loginBtn.enabled = NO;
    // KVO
    // 把监听redV的center属性改变转换成信号，只要值改变就会发送信号
    // observer:可以传入nil
//    [[self.redView rac_valuesAndChangesForKeyPath:@"login" options:NSKeyValueObservingOptionNew observer:nil] subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//    }];
    
    [RACObserve(self.redView, login) subscribeNext:^(id x) {
        NSLog(@"rac %@",x);
    }];
    
    
    // 监听事件
    // 把按钮点击事件转换为信号，点击按钮，就会发送信号
//    [[self.redBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
//        NSLog(@"按钮点击 %@",x);
//    }];
    
    //textField 监听文本框的文字改变
//    [self.textField.rac_textSignal subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//    }];
    
    // 代替通知
    // 把监听到的通知转换信号
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"change" object:nil] subscribeNext:^(id x) {
        NSLog(@"接收到通知");
    }];
    
    //检测输入文字的多少 backgroundcolor
    //监听命令是否执行完毕,默认会来一次，可以直接跳过，skip表示跳过第一次信号。
    RAC(self.textField, backgroundColor) = [[[self.textField.rac_textSignal skip:2]
                                             map:^id(NSString *value) {
                                                 return @(value.length>3);
                                             }] map:^id(id value) {
                                                 return [value boolValue]?[UIColor redColor]:[UIColor greenColor];
                                             }];
    //检测点击btn设置不同的颜色
    RAC(self.redBtn,backgroundColor) = [[self.redBtn rac_signalForControlEvents:UIControlEventTouchUpInside] map:^id(UIButton *btn) {
        btn.selected = !btn.selected;
        NSLog(@"%d",btn.selected);
        return btn.selected ? [UIColor greenColor] : [UIColor redColor];
    }];
    
    [self setUpLogin];
    
}

- (void)setUpLogin
{
    //用户名的限制
    RACSignal *userSingnal = [self.userTextField.rac_textSignal map:^id(NSString *text) {
        return @(text.length>3);
    }];
    RAC(self.userTextField,backgroundColor) = [userSingnal map:^id(NSNumber *value) {
        return [value boolValue] ? [UIColor greenColor] : [UIColor redColor];
    }];
    
    //用户密码的限制
    RACSignal *passwordSingnal = [self.passwordTextField.rac_textSignal map:^id(NSString *text) {
        return @(text.length>3);
    }];
    RAC(self.passwordTextField,backgroundColor) = [passwordSingnal map:^id(NSNumber *value) {
        return [value boolValue] ? [UIColor greenColor] : [UIColor redColor];
    }];
    @weakify(self);
    
    //根据用户名和密码输入的个数来判断Btn的状态
    [[RACSignal combineLatest:@[userSingnal,passwordSingnal] reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid){
        return @([usernameValid boolValue] && [passwordValid boolValue]);
    }] subscribeNext:^(NSNumber *loginBtnStatus) {
        @strongify(self);
        self.loginBtn.enabled =  [loginBtnStatus boolValue];
    }];
    
    //map操作创建并返回了登录信号，这意味着后续步骤都会收到一个RACSignal。这就是你在subscribeNext:这步看到的。
    //解决的方法很简单，只需要把map操作改成flattenMap就可以了
    [[[[self.loginBtn rac_signalForControlEvents:UIControlEventTouchUpInside] doNext:^(id x) {
        @strongify(self);
        self.loginBtn.enabled = NO;
    }] flattenMap:^id(id value) {
        @strongify(self);
        return [self loginStatus];
    }] subscribeNext:^(NSNumber *signedIn) {
        @strongify(self);
        BOOL success = [signedIn boolValue];
        if (success) {
            NSLog(@"登陆成功");
            SecondViewController *secondVC = [[SecondViewController alloc] init];
            [self.navigationController pushViewController:secondVC animated:YES];
        }else {
            NSLog(@"用户名或密码错误");
        }
//        @strongify(self);
//        [self loginStatus];
//        NSLog(@"%d",self.isLogin);
//        if (self.isLogin) {
//            NSLog(@"登陆成功");
//        }else {
//            NSLog(@"用户名或密码错误");
//        }
        
    }];

}


- (RACSignal *)loginStatus
{
    @weakify(self);
    //限制用户名和密码都是login
    RACSignal *userSingnal = [self.userTextField.rac_textSignal map:^(NSString *userName) {
        return @([userName isEqualToString:@"login"]);
    }];
    
    RACSignal *passwordSingnal = [self.passwordTextField.rac_textSignal map:^(NSString *password) {
        return @([password isEqualToString:@"login"]);
    }];
    
    //聚合信号
    [[RACSignal combineLatest:@[userSingnal,passwordSingnal] reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid){
        return @([usernameValid boolValue] && [passwordValid boolValue]);
    }] subscribeNext:^(NSNumber *loginBtnStatus) {
        @strongify(self);
        self.isLogin = [loginBtnStatus boolValue];
    }];
    //返回一个信号
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@(self.isLogin)];
        [subscriber sendCompleted];
        return nil;
    }];
}
- (IBAction)push:(id)sender {
    SecondViewController *secondVC = [[SecondViewController alloc] init];
     // 设置代理信号
    secondVC.delegateSignal =  [RACSubject subject];
    
    // 订阅代理信号
    [secondVC.delegateSignal  subscribeNext:^(id x) {
        
        NSLog(@"点击了通知按钮 %@",x);
    }];
    [self.navigationController pushViewController:secondVC animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
