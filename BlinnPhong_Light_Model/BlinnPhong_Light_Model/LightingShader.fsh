/**
 *参考网址：https://learnopengl-cn.readthedocs.io/zh/latest/02%20Lighting/02%20Basic%20Lighting/
 */

precision highp float;

uniform sampler2D TextureMap;

varying mediump vec2 vTexCoordinates;

/**
 *环境光 dark gray
 */
mediump vec4 AmbientMaterialColor=vec4(0.1,0.1,0.1,1.0);

/**
 *漫反射光 gray
 */
mediump vec4 DiffuseMaterialColor=vec4(0.5,0.5,0.5,1.0);

/**
 *镜面反射光 white
 */
mediump vec4 SpecularMaterialColor=vec4(1.0,1.0,1.0,1.0);

/**
 *亮度
 */
mediump float Shininess=5.0;

varying mediump vec4 lightPosition;

varying mediump vec4 positionInViewSpace;

varying mediump vec3 normalInViewSpace;

struct Lights{
    /**
     *光照向量
     */
    mediump vec3 L;
    /**
     *光照度
     */
    lowp float iL;
    /**
     *光强度
     */
    float pointLightIntensity;
    /**
     *衰减
     */
    vec3 pointLightAttenuation;
    /**
     *颜色
     */
    vec3 lightColor;
    /**
     *位置
     */
    vec4 lightPosition;
};

Lights light;

/**
 *compute the light direction vector, illuminance and attenuation
 */
void computePointLightValues(in mediump vec4 surfacePosition);

/**
 *ambient+diffuse+specular lights
 */
mediump vec3 addAmbientDiffuseSpecularLights(in mediump vec4 surfacePosition,in mediump vec3 surfaceNormal);

/**
 *环境光计算
 */
mediump vec3 computeAmbientComponent();

/**
 *漫反射计算
 */
mediump vec3 computeDiffuseComponent(in mediump vec3 surfaceNormal);

/**
 *镜面光计算
 */
mediump vec3 computeSpecularComponent(in mediump vec3 surfaceNormal,in mediump vec4 surfacePosition);


void computePointLightValues(in mediump vec4 surfacePosition){
    
    light.L=light.lightPosition.xyz-surfacePosition.xyz;

    mediump float dist=length(light.L);

    light.L=light.L/dist;

    //k_c*1.0+K_1*dist+K_q*dist*dist

    mediump float distAtten=dot(light.pointLightAttenuation,vec3(1.0,dist,dist*dist));

    light.iL=light.pointLightIntensity/distAtten;
    
}

/**
 *add the ambient+diffuse+specular lights
 */
mediump vec3 addAmbientDiffuseSpecularLights(in mediump
                               vec4 surfacePosition,in mediump vec3 surfaceNormal){
    
    return computeAmbientComponent()+computeDiffuseComponent(surfaceNormal)+computeSpecularComponent(surfaceNormal,surfacePosition);

}

mediump vec3 computeAmbientComponent(){
    /**
     *环境光 Equation
     *CA=iL*LightAmbientColor*MaterialAmbientColor
     */
    return light.iL*(light.lightColor)*AmbientMaterialColor.xyz;
    
}

mediump vec3 computeDiffuseComponent(in mediump vec3 surfaceNormal){
    /**
     *漫反射 Equation
     *CD=iL*max(0,dot(LightDirection,SurfanceNormal))*LightDiffuseColor*diffuseMaterial
     */
    return light.iL*max(0.0,dot(surfaceNormal,light.L))*(light.lightColor)*DiffuseMaterialColor.rgb;
    
}

mediump vec3 computeSpecularComponent(in mediump vec3 surfaceNormal,in mediump vec4 surfacePosition){
    
    mediump vec3 viewVector=normalize(-surfacePosition.xyz);

    /**
     *reflection vector Equation
     *r=2*dot(L,n)*n-L
     */
    mediump vec3 reflectionVector=2.0*dot(light.L,surfaceNormal)*surfaceNormal-light.L;

    /**
     *镜面光 Equation
     *CS=iL*(max(0,dot(r,v))^m)*LightSpecularColor*specularMaterial
     */
    return (dot(surfaceNormal,light.L)<=0.0)?vec3(0.0,0.0,0.0):(light.iL*(light.lightColor)*SpecularMaterialColor.rgb*pow(max(0.0,dot(reflectionVector,viewVector)),Shininess));
    
}


void main() {
    light.lightPosition=lightPosition;

    light.pointLightIntensity=2.0;

    light.pointLightAttenuation=vec3(1.0,0.0,0.0);

    light.lightColor=vec3(1.0,1.0,1.0);

    mediump vec4 finalLightColor=vec4(0.0);

    finalLightColor.a=1.0;

    computePointLightValues(positionInViewSpace);

    finalLightColor.rgb+=vec3(addAmbientDiffuseSpecularLights(positionInViewSpace,normalInViewSpace));

    mediump vec4 textureColor=texture2D(TextureMap,vTexCoordinates.st);

    mediump vec4 finalMixedColor=mix(textureColor,finalLightColor,0.3);

    gl_FragColor = finalMixedColor;
}
