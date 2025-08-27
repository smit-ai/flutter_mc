#version 460 core

layout(binding = 0)uniform MaterialBlock {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
} material;

layout(binding = 1) uniform LightBlock {
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
} light;
layout(binding = 2) uniform CameraBlock {
    vec3 viewPos;
} camera;
layout(binding = 3) uniform sampler2D tex;


in vec2 v_texture_coords;
in vec3 v_normal;
in vec3 v_fragPos;

out vec4 frag_color;

void main() {
    vec4 textColor4=texture(tex, v_texture_coords);
    // 纹理采样
    vec3 texColor = textColor4.rgb;

    // 法线 & 光照方向
    vec3 norm = normalize(v_normal);
    vec3 lightDir = normalize(-light.direction);

    // 环境光
    vec3 ambient = light.ambient * material.ambient * texColor;

    // 漫反射
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = light.diffuse * (diff * material.diffuse) * texColor;

    // 高光 (使用Blinn-Phong模型)
    vec3 viewDir = normalize(camera.viewPos - v_fragPos);
    vec3 halfwayDir = normalize(lightDir + viewDir);
    float shine = max(material.shininess, 1.0); // 确保shininess至少为1
    float spec = pow(max(dot(norm, halfwayDir), 0.0), shine);
    vec3 specular = light.specular * spec * material.specular;
//    vec3 specular = light.specular *spec*vec3(1,0,1);

    vec3 result = ambient + diffuse + specular;
    frag_color = vec4(result,textColor4.a);
//    frag_color = texture(tex, v_texture_coords);
}
