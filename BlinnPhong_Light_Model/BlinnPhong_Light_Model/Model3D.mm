//
//  Model3D.cpp
//  BlinnPhong_Light_Model
//
//  Created by 黄世平 on 2022/4/20.
//

#include "Model3D.hpp"
#include "lodepng.h"
#include <vector>
#include <iostream>
#include "Fort.h"

static GLubyte shaderText[MAX_SHADER_LENGTH];

Model3D::Model3D(float uScreenWidth,float uScreenHeight){
    
    screenWidth=uScreenWidth;
    screenHeight=uScreenHeight;
}

void Model3D::setupOpenGL(){
    
    NSString* vshFile = [[NSBundle mainBundle] pathForResource:@"LightingShader.vsh" ofType:nil];
    NSString* fshFile = [[NSBundle mainBundle] pathForResource:@"LightingShader.fsh" ofType:nil];
    
    loadShaders([vshFile UTF8String], [fshFile UTF8String]);
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1,&vertexArrayObject);
    
    glBindVertexArrayOES(vertexArrayObject);
    
    glGenBuffers(1, &vertexBufferObject);
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(fort_vertices)+sizeof(fort_normal)+sizeof(fort_uv), NULL, GL_STATIC_DRAW);
    
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(fort_vertices), fort_vertices);
    
    glBufferSubData(GL_ARRAY_BUFFER, sizeof(fort_vertices), sizeof(fort_normal), fort_normal);
    
    glBufferSubData(GL_ARRAY_BUFFER, sizeof(fort_vertices)+sizeof(fort_normal), sizeof(fort_uv), fort_uv);
    
    positionLocation=glGetAttribLocation(programObject, "position");
    
    normalLocation=glGetAttribLocation(programObject, "normal");
    
    uvLocation=glGetAttribLocation(programObject, "texCoord");
    
    modelViewProjectionUniformLocation = glGetUniformLocation(programObject,"modelViewProjectionMatrix");
    
    modelViewUniformLocation=glGetUniformLocation(programObject, "modelViewMatrix");
    
    normalMatrixUniformLocation = glGetUniformLocation(programObject,"normalMatrix");
    
    glEnableVertexAttribArray(positionLocation);

    glEnableVertexAttribArray(normalLocation);
    
    glEnableVertexAttribArray(uvLocation);
    
    glVertexAttribPointer(positionLocation, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid *) 0);
    
    glVertexAttribPointer(normalLocation, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)sizeof(fort_vertices));
    
    glVertexAttribPointer(uvLocation, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)(sizeof(fort_vertices)+sizeof(fort_normal)));

    GLuint elementBuffer;
    glGenBuffers(1, &elementBuffer);
  
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
    
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(fort_index), fort_index, GL_STATIC_DRAW);
    
    glActiveTexture(GL_TEXTURE0);
    
    glGenTextures(1, &textureID[0]);
 
    glBindTexture(GL_TEXTURE_2D, textureID[0]);
    
    NSString* fortImageFile = [[NSBundle mainBundle] pathForResource:@"fort.png" ofType:nil];
    if(convertImageToRawImage([fortImageFile UTF8String])){
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, &image[0]);
    
    }
    
    UVMapUniformLocation=glGetUniformLocation(programObject, "TextureMap");
    
    glBindVertexArrayOES(0);
    
    setTransformation();
    
}

void Model3D::update(float dt){
    modelSpace=GLKMatrix4Rotate(modelSpace, dt, 0.0f, 0.0f, 1.0f);
    
    modelWorldSpace=GLKMatrix4Multiply(worldSpace,modelSpace);
    
    modelWorldViewSpace = GLKMatrix4Multiply(cameraViewSpace, modelWorldSpace);
    
    modelWorldViewProjectionSpace = GLKMatrix4Multiply(projectionSpace, modelWorldViewSpace);
    
    normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelWorldViewSpace), NULL);
    
    glUniformMatrix4fv(modelViewProjectionUniformLocation, 1, 0, modelWorldViewProjectionSpace.m);
    
    glUniformMatrix3fv(normalMatrixUniformLocation, 1, 0, normalMatrix.m);
}

void Model3D::draw(){
    glUseProgram(programObject);
    
    glBindVertexArrayOES(vertexArrayObject);
    
    glActiveTexture(GL_TEXTURE0);
    
    glBindTexture(GL_TEXTURE_2D, textureID[0]);
    
    glUniform1i(UVMapUniformLocation, 0);
    
    glDrawElements(GL_TRIANGLES, sizeof(fort_index)/4, GL_UNSIGNED_INT,(void*)0);
    
    glBindVertexArrayOES(0);
}



void Model3D::setTransformation(){
    modelSpace=GLKMatrix4Identity;
    
    GLKMatrix4 blenderSpace=GLKMatrix4MakeAndTranspose(1,0,0,0,
                                                        0,0,1,0,
                                                        0,-1,0,0,
                                                        0,0,0,1);
    modelSpace=GLKMatrix4Multiply(blenderSpace, modelSpace);
    worldSpace=GLKMatrix4Identity;
    modelWorldSpace=GLKMatrix4Multiply(worldSpace,modelSpace);
    cameraViewSpace = GLKMatrix4MakeTranslation(0.0f, -3.0f, -15.0f);
    modelWorldViewSpace = GLKMatrix4Multiply(cameraViewSpace, modelWorldSpace);
    projectionSpace = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0f), fabsf(screenWidth/screenHeight), 0.1f, 100.0f);
    modelWorldViewProjectionSpace = GLKMatrix4Multiply(projectionSpace, modelWorldViewSpace);
    normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelWorldViewSpace), NULL);
    glUniformMatrix4fv(modelViewProjectionUniformLocation, 1, 0, modelWorldViewProjectionSpace.m);
    glUniformMatrix3fv(normalMatrixUniformLocation, 1, 0, normalMatrix.m);
    glUniformMatrix4fv(modelViewUniformLocation, 1, 0, modelWorldViewSpace.m);
}

bool Model3D::convertImageToRawImage(const char *uTexture){
    
    bool success=false;
    unsigned error = lodepng::decode(image, imageWidth, imageHeight,uTexture);
    if(error) {
        std::cout << "Couldn't decode the image. decoder error " << error << ": " << lodepng_error_text(error) << std::endl;
        
    } else {
        unsigned char* imagePtr=&image[0];
        
        int halfTheHeightInPixels=imageHeight/2;
        
        int heightInPixels=imageHeight;
        
        int numColorComponents=4;
        
        int widthInChars=imageWidth*numColorComponents;
        
        unsigned char *top=NULL;
        
        unsigned char *bottom=NULL;
        
        unsigned char temp=0;
        
        for( int h = 0; h < halfTheHeightInPixels; ++h ) {
            top = imagePtr + h * widthInChars;
            bottom = imagePtr + (heightInPixels - h - 1) * widthInChars;
            for( int w = 0; w < widthInChars; ++w ) {
                // Swap the chars around.
                temp = *top;
                *top = *bottom;
                *bottom = temp;
                ++top;
                ++bottom;
            }
        }
        success=true;
    }
    
    return success;
}



void Model3D::loadShaders(const char* uVertexShaderProgram, const char* uFragmentShaderProgram){
    GLuint VertexShader;
    GLuint FragmentShader;
    
    VertexShader = glCreateShader(GL_VERTEX_SHADER);
    FragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    
    if(loadShaderFile(uVertexShaderProgram, VertexShader)==false){
        glDeleteShader(VertexShader);
        glDeleteShader(FragmentShader);
        fprintf(stderr, "The shader at %s could not be found.\n", uVertexShaderProgram);
        
    } else {
        fprintf(stderr,"Vertex Shader was loaded successfully\n");
        
    }
    if(loadShaderFile(uFragmentShaderProgram, FragmentShader)==false){
        glDeleteShader(VertexShader);
        glDeleteShader(FragmentShader);
        fprintf(stderr, "The shader at %s could not be found.\n", uFragmentShaderProgram);
    } else {
        fprintf(stderr,"Fragment Shader was loaded successfully\n");
        
    }

    glCompileShader(VertexShader);
    glCompileShader(FragmentShader);

    GLint testVal;
    
    glGetShaderiv(VertexShader, GL_COMPILE_STATUS, &testVal);
    if(testVal == GL_FALSE) {
        char infoLog[1024];
        glGetShaderInfoLog(VertexShader, 1024, NULL, infoLog);
        fprintf(stderr, "The shader at %s failed to compile with the following error:\n%s\n", uVertexShaderProgram, infoLog);
        glDeleteShader(VertexShader);
        glDeleteShader(FragmentShader);
        
    } else {
        fprintf(stderr,"Vertex Shader compiled successfully\n");
    }
    
    glGetShaderiv(FragmentShader, GL_COMPILE_STATUS, &testVal);
    if(testVal == GL_FALSE) {
        char infoLog[1024];
        glGetShaderInfoLog(FragmentShader, 1024, NULL, infoLog);
        fprintf(stderr, "The shader at %s failed to compile with the following error:\n%s\n", uFragmentShaderProgram, infoLog);
        glDeleteShader(VertexShader);
        glDeleteShader(FragmentShader);
        
    } else {
        fprintf(stderr,"Fragment Shader compiled successfully\n");
    }

    programObject = glCreateProgram();
    
    glAttachShader(programObject, VertexShader);
    glAttachShader(programObject, FragmentShader);
    
    glLinkProgram(programObject);
    
    glGetProgramiv(programObject, GL_LINK_STATUS, &testVal);
    if(testVal == GL_FALSE) {
        char infoLog[1024];
        glGetProgramInfoLog(programObject, 1024, NULL, infoLog);
        fprintf(stderr,"The programs %s and %s failed to link with the following errors:\n%s\n",
                uVertexShaderProgram, uFragmentShaderProgram, infoLog);
        glDeleteProgram(programObject);
        
    } else {
        fprintf(stderr,"Shaders linked successfully\n");
    }
    
    glDeleteShader(VertexShader);
    glDeleteShader(FragmentShader);
    glUseProgram(programObject);
}

bool Model3D::loadShaderFile(const char *szFile, GLuint shader) {
    GLint shaderLength = 0;
    FILE *fp;
    fp = fopen(szFile, "r");
    if(fp != NULL) {
        while (fgetc(fp) != EOF)
            shaderLength++;
        
        if(shaderLength > MAX_SHADER_LENGTH) {
            fclose(fp);
            return false;
        }
        
        /**Go back to beginning of file*/
        rewind(fp);
        fread(shaderText, 1, shaderLength, fp);
        
        /**Make sure it is null terminated and close the file*/
        shaderText[shaderLength] = '\0';
        fclose(fp);
    } else {
        return false;
    }
    
    loadShaderSrc((const char *)shaderText, shader);
    return true;
}

void Model3D::loadShaderSrc(const char *szShaderSrc, GLuint shader) {
    GLchar *fsStringPtr[1];
    fsStringPtr[0] = (GLchar *)szShaderSrc;
    glShaderSource(shader, 1, (const GLchar **)fsStringPtr, NULL);
}

void Model3D::teadDownOpenGL(){
    glDeleteBuffers(1, &vertexBufferObject);
    glDeleteVertexArraysOES(1, &vertexArrayObject);
    if (programObject) {
        glDeleteProgram(programObject);
        programObject = 0;
        
    }
}

