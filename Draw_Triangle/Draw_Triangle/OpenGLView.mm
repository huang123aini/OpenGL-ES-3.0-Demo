//
//  OpenGLView.m
//  Draw_Triangle
//
//  Created by huangshiping on 2022/3/18.
//

#import "OpenGLView.h"
#include <stdlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

@interface OpenGLView()
{
    NSInteger animation_frame_interval;
    CADisplayLink* display_link;
}

- (void)setupLayer;
- (void)setupContext;
- (void)setupRenderBuffer;
- (void)destoryRenderAndFrameBuffer;
- (void)render;

@end

static GLuint programObject;

@implementation OpenGLView


- (NSInteger) animationFrameInterval {
    return animation_frame_interval;
}

- (void) setAnimationFrameInterval:(NSInteger)frameInterval {
    if (frameInterval >= 1) {
        animation_frame_interval = frameInterval;
        if (_animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void) drawView:(id)sender
{
    [EAGLContext setCurrentContext:egl_context];
    [self render];
    
}

- (void) startAnimation {
    if (!_animating) {
        display_link = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView:)];
        [display_link setFrameInterval:animation_frame_interval];
        [display_link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _animating = TRUE;
    }
}

- (void)stopAnimation {
    if (_animating) {
        [display_link invalidate];
        display_link = nil;
        _animating = FALSE;
    }
}


+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    eagl_layer = (CAEAGLLayer*) self.layer;
    eagl_layer.opaque = YES;
    eagl_layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)setupContext {
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES3;
    egl_context = [[EAGLContext alloc] initWithAPI:api];
    if (!egl_context) {
        NSLog(@"Failed to initialize OpenGLES 3.0 context");
        exit(1);
    }
    if (![EAGLContext setCurrentContext:egl_context]) {
        egl_context = nil;
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &color_render_buffer);
    glBindRenderbuffer(GL_RENDERBUFFER, color_render_buffer);
    [egl_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eagl_layer];
}

- (void)setupFrameBuffer {
    glGenFramebuffers(1, &frame_buffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frame_buffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, color_render_buffer);
}

- (void)destoryRenderAndFrameBuffer {
    glDeleteFramebuffers(1, &frame_buffer);
    frame_buffer = 0;
    glDeleteRenderbuffers(1, &color_render_buffer);
    color_render_buffer = 0;
}

- (void)render {
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glClearColor(1.f, 0.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    /**
     *绘制三角形
     */
    renderTriangle();

    [egl_context presentRenderbuffer:GL_RENDERBUFFER];
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];
        [self setupContext];
        initOpenGL();
        animation_frame_interval = 1;
        [self startAnimation];
    }
    return self;
}

- (void)layoutSubviews {
    [EAGLContext setCurrentContext:egl_context];
    [self destoryRenderAndFrameBuffer];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
}


GLuint LoadShader ( GLenum type, const char *shaderSrc ) {
   GLuint shader = 0;
   GLint compiled;
   shader = glCreateShader ( type );
   if ( !shader ) {
      return 0;
   }

   glShaderSource( shader, 1, &shaderSrc, 0 );
   glCompileShader( shader );
   glGetShaderiv( shader, GL_COMPILE_STATUS, &compiled );
   if ( !compiled ) {
      GLint infoLen = 0;
      glGetShaderiv ( shader, GL_INFO_LOG_LENGTH, &infoLen );
      if ( infoLen > 1 ) {
         char *infoLog = static_cast<char*>(malloc ( sizeof ( char ) * infoLen ));
         glGetShaderInfoLog ( shader, infoLen, NULL, infoLog );
         printf("glGetShaderInfoLog  error:%s \n", infoLog);
         free ( infoLog );
      }
      glDeleteShader ( shader );
      return 0;
   }
   return shader;
}

int initOpenGL(void) {
    char vShaderStr[] =
                "#version 300 es \n"
                "precision highp float;\n"
                "layout (location = 0) in vec3 Position;\n"
                "void main()\n"
                "{\n"
                "    gl_Position = vec4(Position.xy,0.0,1.0);\n"
                "}\n";

    char fShaderStr[] =
                     "#version 300 es \n"
                 "precision mediump float;\n"
                     "layout (location = 0) out vec4 Out_Color;\n"
                     "void main()\n"
                     "{\n"
                     "    Out_Color = vec4(0.0, 1.0, 0.0, 1.0);\n"
                     "}\n";

    GLuint vertexShader;
    GLuint fragmentShader;
    GLint linked;

    vertexShader = LoadShader ( GL_VERTEX_SHADER, vShaderStr);
    fragmentShader = LoadShader ( GL_FRAGMENT_SHADER, fShaderStr );

    programObject = glCreateProgram ();

    if ( programObject == 0 ) {
          printf("programObject ====0 error.\n");
       return 0;
    }
    glAttachShader ( programObject, vertexShader );
    glAttachShader ( programObject, fragmentShader );
    glLinkProgram ( programObject );
    glGetProgramiv ( programObject, GL_LINK_STATUS, &linked );
    if (!linked) {
       GLint infoLen = 0;
       glGetProgramiv ( programObject, GL_INFO_LOG_LENGTH, &infoLen );
       if ( infoLen > 1 ) {
          char *infoLog = static_cast<char*>(malloc ( sizeof ( char ) * infoLen ));
          glGetProgramInfoLog ( programObject, infoLen, NULL, infoLog );
                 printf("glGetProgramInfoLog error: %s.\n", infoLog);
          free ( infoLog );
       }
       glDeleteProgram (programObject);
       return EXIT_FAILURE;
    }

    glDeleteShader(fragmentShader);
    glDeleteShader(vertexShader);

    return EXIT_SUCCESS;
}

void renderTriangle() {
    
    GLfloat vTriangle[] = {
           -0.5f, -0.5f, 0.0f,
           0.f, 0.5f, 0.0f,
           0.5f, -0.5f, 0.0f
    };
    glUseProgram(programObject);
    glVertexAttribPointer (0, 3, GL_FLOAT, GL_FALSE, 0, vTriangle);
    glEnableVertexAttribArray ( 0 );
    glDrawArrays ( GL_TRIANGLES, 0, 3 );
}


@end
