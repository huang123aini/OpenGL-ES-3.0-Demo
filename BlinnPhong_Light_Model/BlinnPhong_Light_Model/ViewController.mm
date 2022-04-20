//
//  ViewController.m
//  Blinn_Phong_Lighting_Demo
//
//  Created by 黄世平 on 2022/4/19.
//

#import "ViewController.h"
#include "Model3D.hpp"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    //2. Check if the context was successful
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }

    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    view.enableSetNeedsDisplay=60.0;
    
    [EAGLContext setCurrentContext:self.context];
    
    //6. create a Character class instance
    //Note, since the ios device will be rotated, the input parameters of the character constructor
    //are swapped.
    model3d=new Model3D(self.view.bounds.size.height,self.view.bounds.size.width);
    
    //7. Begin the OpenGL setup for the character
    model3d->setupOpenGL();
    
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    model3d->update(0.03);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //1. Clear the color to black
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    
    //2. Clear the color buffer and depth buffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //3. Render the character
    model3d->draw();
}

- (void)dealloc {
    model3d->teadDownOpenGL();
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    _context  = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        //call teardown
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
    
    // Dispose of any resources that can be recreated.
}


@end
