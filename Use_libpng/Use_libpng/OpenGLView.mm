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
#include "ImageParse.hpp"

@interface OpenGLView()
{
    NSInteger animation_frame_interval;
    CADisplayLink* display_link;
    ImageParse* image_parse;
}

- (void)setupLayer;
- (void)setupContext;
- (void)setupRenderBuffer;
- (void)destoryRenderAndFrameBuffer;
- (void)render;

@end

static GLuint programObject;
GLuint aPosition;
GLuint aTexCoord;
GLuint uSampler;
GLuint texture_id;
GLuint vao_;


enum {
    position_attribute,
    texcoord_attribute,
};

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
     *绘制2D图片
     */
    renderImage();
    [egl_context presentRenderbuffer:GL_RENDERBUFFER];
}


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];
        [self setupContext];
        initOpenGL();
        /**
         *生成VAO
         */
        [self setupVAOs];
        /**
         *生成纹理
         */
        
        texture_id = [self createTextureFromFile:[[NSBundle mainBundle] pathForResource:@"duck.png" ofType:nil]];
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


-(GLuint)createTextureFromFile:(NSString*) filePath {
    /**
     *读取图片的buffer内容
     */
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    unsigned char* imagebuffer = (unsigned char*)([data bytes]);
    image_parse = new ImageParse();
    /**
     *加载png data
     */
    image_parse->LoadPngData(imagebuffer, [data length]);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    /**
     *通过解析的png数据作为 TexImage2D的数据
     */
    
    int width  = 128;
    int height = 128;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, image_parse->GetData());
    return texName;
}

//-(GLuint)createTextureWithImage:(UIImage*)image {
//    CGImageRef spriteImage = image.CGImage;
//    GLuint width = (GLuint)CGImageGetWidth(spriteImage);
//    GLuint height = (GLuint)CGImageGetHeight(spriteImage);
//    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
//
//    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
//
//    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
//    CGContextRelease(spriteContext);
//    GLuint texName;
//    glGenTextures(1, &texName);
//    glBindTexture(GL_TEXTURE_2D, texName);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
//    free(spriteData);
//    return texName;
//}


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
   } else {
       NSLog(@"shader source compile is success. \n");
   }
   return shader;
}

int initOpenGL(void) {
    char vShaderStr[] =
                "#version 300 es \n"
                "precision highp float;\n"
                "layout (location = 0) in vec3 aPosition;\n"
                "layout (location = 1) in vec2 aTexCoord;\n"
                "out vec2 vTexCoord;\n"
                "void main()\n"
                "{\n"
                "    gl_Position = vec4(aPosition.xy,0.0,1.0);\n"
                "    vTexCoord = aTexCoord;\n"
                "}\n";

    char fShaderStr[] =
                 "#version 300 es \n"
                 "precision mediump float;\n"
                 "layout (location = 0) out vec4 outColor;\n"
                 "in vec2 vTexCoord;\n"
                 "uniform sampler2D uSampler; \n"
                 "void main()\n"
                 "{\n"
                 "    outColor = vec4(texture(uSampler,vTexCoord).rgb, 1.0);\n"
                 //" outColor = vec4(0.0, 1.0, 0.0, 1.0);\n"
                 "}\n";

    GLuint vertexShader;
    GLuint fragmentShader;
    GLint linked;

    vertexShader = LoadShader(GL_VERTEX_SHADER, vShaderStr);
    fragmentShader = LoadShader(GL_FRAGMENT_SHADER, fShaderStr );

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
    } else {
        NSLog(@"gl program is success. \n");
    }
    
    glUseProgram(programObject);
    
//    aPosition = glGetAttribLocation(programObject, "aPosition");
//    aTexCoord = glGetAttribLocation(programObject, "aTexCoord");
//    uSampler = glGetUniformLocation(programObject, "uSampler");
    
    glBindAttribLocation(programObject, position_attribute, "aPosition");
    glBindAttribLocation(programObject, texcoord_attribute, "aTexCoord");

    glDeleteShader(fragmentShader);
    glDeleteShader(vertexShader);

    return EXIT_SUCCESS;
}


static const GLfloat vertices[] = {
       -0.5f, -0.5f, 0.0f,
       0.5f, -0.5f, 0.f,
       -0.5f, 0.5f, 0.f,
       0.5f, 0.5f, 0.f,
};

static const GLfloat texCoords[] = {
    0.f, 1.f,
    1.f, 1.f,
    0.f, 0.f,
    1.f, 0.f,
};

static const GLubyte indices[] = {
    0,1,2,
    2,1,3
};


- (void)setupVAOs {
    
    /**
     *创建一个VAO用于缓存VBOs
     */
    glGenVertexArrays(1, &vao_);
    glBindVertexArray(vao_);
    
    /**
     *顶点数据
     */
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(position_attribute);
    glVertexAttribPointer(position_attribute, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 3, 0);
    
    
    /**
     *纹理数据
     */
    GLuint texCoordBuffer;
    glGenBuffers(1, &texCoordBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, texCoordBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(texCoords), texCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(texcoord_attribute);
    glVertexAttribPointer(texcoord_attribute, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 2, 0);
    
    /**
     *索引数据
     */
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
}

void renderImage() {
    
    /**
     *use program
     */
    glUseProgram(programObject);
    
    /**
     *绑定VAO
     */
    glBindVertexArray(vao_);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture_id);
    glUniform1i(uSampler, 0);

    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_BYTE, 0);
}

-(void)destroyVAO:(GLuint) vaoName
{
    GLuint index;
    GLuint bufName;
    glBindVertexArray(vaoName);
    for(index = 0; index < 16; index++)
    {
        glGetVertexAttribiv(index , GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
        
        if(bufName) {
            /**
             *删除绑定的VBO
             */
            glDeleteBuffers(1, &bufName);
        }
    }
    /**
     *获取绑定的EBO
     */
    glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
    
    // If there was a element array VBO set in the VAO
    if(bufName)
    {
        /**删除EBO*/
        glDeleteBuffers(1, &bufName);
    }
    
    //删除VAO
    glDeleteVertexArrays(1, &vaoName);
}

-(void)dealloc {
    if(image_parse) {
        delete image_parse;
        image_parse = nullptr;
    }
    
    glDeleteTextures(1, &texture_id);
    glDeleteProgram(programObject);
    /**
     *删除VAO
     */
    [self destroyVAO:vao_];
}


@end
