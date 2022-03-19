//
//  OpenGLView.h
//  Draw_Triangle
//
//  Created by huangshiping on 2022/3/18.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/ES3/glext.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenGLView : UIView
{
    CAEAGLLayer* eagl_layer;
    EAGLContext* egl_context;
    GLuint color_render_buffer;
    GLuint frame_buffer;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;


- (void) startAnimation;
- (void) stopAnimation;
- (void) drawView:(id)sender;

@end

NS_ASSUME_NONNULL_END
