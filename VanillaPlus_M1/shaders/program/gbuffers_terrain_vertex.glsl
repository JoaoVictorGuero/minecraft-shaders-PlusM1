out vec2 texcoord;
out vec2 lmcoord;
out vec4 glColor;
out vec3 normal;
out vec4 viewPos;
flat out int blockId;
in vec4 mc_Entity;
#ifdef VP_BLOCK_ENTITY
uniform int blockEntityId;
#endif
in vec2 mc_midTexCoord;
uniform mat4 gbufferModelViewInverse;
#include "/lib/wind.glsl"
void main() {
    #ifdef VP_BLOCK_ENTITY
    blockId = blockEntityId;
    #else
    blockId = int(mc_Entity.x + 0.5);
    #endif
    viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec3 worldPos = (gbufferModelViewInverse * viewPos).xyz + cameraPosition;
    vec3 wind = foliageWind(worldPos, blockId, gl_MultiTexCoord0.t, mc_midTexCoord.y);
    viewPos.xyz += transpose(mat3(gbufferModelViewInverse)) * wind;
    gl_Position = gl_ProjectionMatrix * viewPos;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glColor = gl_Color;
    normal = normalize(gl_NormalMatrix * gl_Normal);
}
