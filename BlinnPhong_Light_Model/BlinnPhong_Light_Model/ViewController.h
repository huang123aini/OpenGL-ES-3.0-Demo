//
//  ViewController.h
//  Blinn_Phong_Lighting_Demo
//
//  Created by 黄世平 on 2022/4/19.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "Model3D.hpp"

@interface ViewController : GLKViewController {
    
Model3D* model3d;
}

@property (strong, nonatomic) EAGLContext *context;

@end

