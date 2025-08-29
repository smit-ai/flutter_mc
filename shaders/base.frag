#version 460 core

layout(binding = 0)uniform MaterialBlock {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    vec4 shininess;//actual shininess is shininess.x
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
layout(binding = 4) uniform FogBlock{
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
    vec3 specular = light.specular * spec * material.specular;

    vec4 result = vec4(ambient + diffuse + specular,textColor4.a);

    //fog
    toCamera.z=toCamera.z*fog.range.z;
    float fogIntensity = smoothstep(fog.range.x, fog.range.y, length(toCamera));
    vec4 finalColor = mix(result, fog.color, fogIntensity);

    frag_color = finalColor;
//    frag_color = texture(tex, v_texture_coords);
}
