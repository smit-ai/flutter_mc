#version 460 core
layout(binding = 6) uniform FrameInfo {
  mat4 mvp;
}frame_info;

in vec3 position;

out vec3 v_fragPos;

void main() {
  gl_Position = frame_info.mvp  * vec4(position, 1.0);
  v_fragPos = position;
}
