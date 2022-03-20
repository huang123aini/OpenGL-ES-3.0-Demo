//
//  ViewController.m
//  Use_libpng
//
//  Created by 黄世平 on 2022/3/19.
//

#import "ViewController.h"
#include "OpenGLView.h"
@interface ViewController ()
{
    OpenGLView* opengl_view;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    opengl_view = [[OpenGLView alloc]  initWithFrame:self.view.frame];
    [self.view addSubview: opengl_view];
}


@end
