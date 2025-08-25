#version 460 core

uniform sampler2D tex;

in vec2 v_texture_coords;
in vec3 v_normal;
out vec4 frag_color;
void main() {
  frag_color = texture(tex, v_texture_coords);
}
