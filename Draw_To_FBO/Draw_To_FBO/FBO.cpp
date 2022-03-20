#include "FBO.h"

void FBO::init(int width, int height) {
    
    width_ = width;
    height_ = height;
    
    fbo_handle = 0;
    glGenFramebuffers(1, &fbo_handle);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo_handle);
    
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        printf("hsp hsp hsp hsp GL_has error.  error:%d  file:%s line:%d \n", error, __FILE__, __LINE__);
    }
    //render color texture
    fbo_texture = 0;
    glGenTextures(1, &fbo_texture);
    //glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, fbo_texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
 
    //depth render buffer
    rbo_depth = 0;
    glGenRenderbuffers(1, &rbo_depth);
    glBindRenderbuffer(GL_RENDERBUFFER, rbo_depth);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);
    error = glGetError();
    if (error != GL_NO_ERROR) {
        printf("hsp hsp hsp hsp GL_has error.  error:%d  file:%s line:%d \n", error, __FILE__, __LINE__);
    }
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, fbo_texture, 0);
   glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rbo_depth);
    GLenum fboStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (fboStatus != GL_FRAMEBUFFER_COMPLETE) {
        printf("hsp hsp hsp framebuffer is not complete . fboStatus:%d \n", fboStatus);
    }
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

GLuint FBO::getFboTexture() {
    return  fbo_texture;
}


FBO::~FBO() {
    glDeleteFramebuffers(1, &fbo_handle);
    glDeleteTextures(1, &fbo_texture);
    glDeleteRenderbuffers(1, &rbo_depth);
}

void FBO::bindFbo() {
    glBindFramebuffer(GL_FRAMEBUFFER, fbo_handle);
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        printf("hsp hsp hsp hsp bindFbo GL_has error.  error:%d  file:%s line:%d \n", error, __FILE__, __LINE__);
    }
}

void FBO::unbindFbo() {
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        printf("hsp hsp hsp hsp unbindFbo GL_has error.  error:%d  file:%s line:%d \n", error, __FILE__, __LINE__);
    }
}

void FBO::drawFbo() {
    glViewport(0, 0, width_ , height_);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void FBO::readFbo(void* buffer) {
 glReadPixels(0, 0, (GLsizei)width_, (GLsizei)height_, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
 unsigned char *ptr = (unsigned char*) buffer;
 printf("FBO::readFBO ptr[0] = %d  ptr[1] = %d  ptr[2] = %d  ptr[3] = %d   \n", (int)ptr[0], (int)ptr[1], (int)ptr[2], (int)ptr[3]);

}
