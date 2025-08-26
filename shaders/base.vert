#version 460 core

uniform FrameInfo {
  mat4 mvp;
}frame_info;
uniform Translation {
    mat4 t;
}translation;

in vec3 position;
in vec3 aNormal;
in vec2 texture_coords;
out vec2 v_texture_coords;
out vec3 v_normal;


void main() {
  v_texture_coords = texture_coords;
  gl_Position = frame_info.mvp * translation.t * vec4(position, 1.0);
  v_normal = aNormal;
}
