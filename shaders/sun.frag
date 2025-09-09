#version 460 core

layout(binding = 5,std140) uniform SunBlock{
    vec4 color;
    vec3 center;
    vec4 edge;//x is start, y is end
} sun;

in vec3 v_fragPos;

out vec4 frag_color;

void main() {
    vec4 transparent=vec4(0,0,0,0);
    vec3 toCenter=sun.center-v_fragPos;
    float distance=length(toCenter);
    float intensity = smoothstep(sun.edge.x, sun.edge.y,distance);
    vec4 finalColor = mix( sun.color,transparent, intensity);

    frag_color = finalColor;
}
