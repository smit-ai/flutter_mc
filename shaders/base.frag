#version 460 core

uniform MaterialBlock {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
} material;

uniform LightBlock {
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
} light;
uniform sampler2D tex;
uniform CameraBlock {
    vec3 viewPos;
}camera;

in vec2 v_texture_coords;
in vec3 v_normal;
in vec3 v_fragPos;

out vec4 frag_color;

void main() {
  frag_color = texture(tex, v_texture_coords);
}
