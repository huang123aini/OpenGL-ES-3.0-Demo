
attribute vec4 position;
attribute vec3 normal;
attribute vec2 texCoord;

varying mediump vec2 vTexCoordinates;

uniform mat4 modelViewProjectionMatrix;

uniform mat4 modelViewMatrix;

uniform mat3 normalMatrix;

varying mediump vec4 positionInViewSpace;

varying mediump vec3 normalInViewSpace;

//6. declare varying position of the light
varying vec4 lightPosition=vec4(5.0,-2.0,5.0,1.0);

void main() {
    
positionInViewSpace=modelViewMatrix*position;

normalInViewSpace=normalMatrix*normal;

lightPosition=modelViewMatrix*lightPosition;

vTexCoordinates=texCoord;

gl_Position = modelViewProjectionMatrix * position;

}
