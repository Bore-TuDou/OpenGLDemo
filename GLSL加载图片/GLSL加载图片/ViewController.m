//
//  ViewController.m
//  GLSL加载图片
//
//  Created by xzkj on 2020/7/31.
//  Copyright © 2020 TuDou. All rights reserved.
//

#import "ViewController.h"
#import "GLView.h"

@interface ViewController ()

@property(nonnull,strong)GLView *myView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor redColor]];
    self.myView = [[GLView alloc]init];
    self.myView.frame = self.view.frame;
    [self.view addSubview:self.myView];
//    self.myView = (GLView *)self.view;
    // Do any additional setup after loading the view.
}


@end
