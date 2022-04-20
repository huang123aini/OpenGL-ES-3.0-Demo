//
//  Model3D.hpp
//  BlinnPhong_Light_Model
//
//  Created by 黄世平 on 2022/4/20.
//

#ifndef Model3D_hpp
#define Model3D_hpp

#include <stdio.h>
#include <math.h>
#include <vector>
#include <string>

#include <GLKit/GLKit.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#define MAX_SHADER_LENGTH   8192

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

class Model3D {
    
private:
    /**
     *Array for textures
     */
    GLuint textureID[16];
   
    GLuint programObject;
    /**
     *VAO
     */
    GLuint vertexArrayObject;
    /**
     *VBO
     */
    GLuint vertexBufferObject;
    
    float aspect;
    
    GLint modelViewProjectionUniformLocation;  //OpenGL location for our MVP uniform
    
    GLint normalMatrixUniformLocation;  //OpenGL location for the normal matrix
    
    GLint modelViewUniformLocation; //OpenGL location for the Model-View uniform
    
    GLint UVMapUniformLocation; //OpenGL location for the Texture Map
    
    //Matrices for several transformation
    GLKMatrix4 projectionSpace;
    
    GLKMatrix4 cameraViewSpace;
    
    GLKMatrix4 modelSpace;
    
    GLKMatrix4 worldSpace;
    
    GLKMatrix4 modelWorldSpace;
    
    GLKMatrix4 modelWorldViewSpace;
    
    GLKMatrix4 modelWorldViewProjectionSpace;
    
    GLKMatrix3 normalMatrix;
    
    float screenWidth;  //Width of current device display
    float screenHeight; //Height of current device display
    
    GLuint positionLocation; //attribute "position" location
    GLuint normalLocation;   //attribute "normal" location
    GLuint uvLocation; //attribute "uv"location
    
    std::vector<unsigned char> image;
    unsigned int imageWidth, imageHeight;
    
public:
    
    Model3D(float uScreenWidth,float uScreenHeight);
    
    ~Model3D();
    
    void setupOpenGL();
    
    void teadDownOpenGL();
    
    void loadShaders(const char* uVertexShaderProgram, const char* uFragmentShaderProgram);
    
    void setTransformation();
    
    void update(float dt);
    
    void draw();
    
    bool loadShaderFile(const char *szFile, GLuint shader);
    
    void loadShaderSrc(const char *szShaderSrc, GLuint shader);
    
    bool convertImageToRawImage(const char *uTexture);
    
    inline float degreesToRad(float angle){return (angle*M_PI/180);};
};


#endif /* Model3D_hpp */
