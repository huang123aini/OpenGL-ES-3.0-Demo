#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/ES3/glext.h>
#include <cstdio>
#include <iostream>

class FBO {

public:
 virtual ~FBO();

int width_;
int height_;
private:
 GLuint fbo_texture;
 GLuint fbo_handle;
 GLuint rbo_depth;

public:
void init(int width, int height);
GLuint getFboTexture();
void bindFbo();
void unbindFbo();
void drawFbo();
void readFbo(void* buffer);
};
