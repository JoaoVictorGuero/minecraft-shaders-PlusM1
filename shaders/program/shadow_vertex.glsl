out vec2 texcoord;
out vec4 glColor;
in vec4 mc_Entity;
in vec2 mc_midTexCoord;
uniform mat4 shadowModelViewInverse;
#include "/lib/wind.glsl"
#include "/lib/shadow_distortion.glsl"
void main() {
    vec4 pos = gl_ModelViewMatrix * gl_Vertex;
    vec3 worldPos = (shadowModelViewInverse * pos).xyz + cameraPosition;
    vec3 wind = foliageWind(worldPos, int(mc_Entity.x + 0.5), gl_MultiTexCoord0.t, mc_midTexCoord.y);
    pos.xyz += transpose(mat3(shadowModelViewInverse)) * wind;
    vec4 clip = gl_ProjectionMatrix * pos;
    clip.xyz = distortShadow(clip.xyz / clip.w) * clip.w;
    gl_Position = clip;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor = gl_Color;
}
