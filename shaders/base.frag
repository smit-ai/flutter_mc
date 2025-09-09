#version 460 core

layout(binding = 0,std140)uniform MaterialBlock {
    vec3 ambient;
    vec3 diffuse;
    vec4 specular;//a is texture specular scale
    vec4 shininess;//actual shininess is shininess.x , shininess.y is specularIntensity decay index
} material;

layout(binding = 1,std140) uniform LightBlock {
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
} light;
layout(binding = 2,std140) uniform CameraBlock {
    vec3 viewPos;
} camera;
layout(binding = 3) uniform sampler2D tex;
layout(binding = 4,std140) uniform FogBlock{
    vec4 color;
    vec4 range;//x is start, y is end, z is height compression
} fog;

in vec2 v_texture_coords;
in vec3 v_normal;
in vec3 v_fragPos;

out vec4 frag_color;

void main() {
    vec4 textColor4=texture(tex, v_texture_coords);
    // 纹理采样
    vec3 texColor = textColor4.rgb;
    //text grey
    float grey=clamp(dot(textColor4.rgb,vec3(0.299, 0.587, 0.114))*material.specular.a,0.1,1.0);

    // 法线 & 光照方向
    vec3 norm = normalize(v_normal);
    vec3 lightDir = normalize(-light.direction);
    vec3 toCamera=camera.viewPos-v_fragPos;

    // 环境光
    vec3 ambient = light.ambient * material.ambient * texColor;

    // 漫反射
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = light.diffuse * (diff * material.diffuse) * texColor;

    // 高光 (使用Blinn-Phong模型)
    vec3 viewDir = normalize(toCamera);
    vec3 halfwayDir = normalize(lightDir + viewDir);
    float shine = max(material.shininess.x, 1.0); // 确保shininess至少为1
    float spec = pow(max(dot(norm, halfwayDir), 0.0), shine);
    vec3 specular = light.specular * spec * material.specular.xyz*grey;

    // 计算高光强度并影响alpha通道
    float specularIntensity = dot(specular, vec3(0.299, 0.587, 0.114)); // 将高光颜色转换为灰度强度
    float alphaWithSpecular = textColor4.a + pow(specularIntensity,material.shininess.y); // 将高光强度添加到alpha值
    alphaWithSpecular = clamp(alphaWithSpecular, 0.0, 1.0); // 确保alpha值在有效范围内

    vec4 result = vec4(ambient + diffuse + specular,alphaWithSpecular);

    //fog
    toCamera.y=toCamera.y*fog.range.z;
    float fogIntensity = smoothstep(fog.range.x, fog.range.y, length(toCamera));
    vec4 finalColor = mix(result, fog.color, fogIntensity);

    frag_color = finalColor;
//    frag_color = texture(tex, v_texture_coords);
}
