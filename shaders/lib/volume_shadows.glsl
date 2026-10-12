#ifndef VP_VOLUME_SHADOWS
#define VP_VOLUME_SHADOWS

uniform sampler2D shadowtex1;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
const bool shadowtex1Nearest = true;
#include "/lib/shadow_distortion.glsl"

float volumeSunVisibility(vec3 playerPos) {
    // Unmapped regions receive no extra light, avoiding leaks at map edges.
    if (length(playerPos.xz) >= shadowDistance * 0.95) return 0.0;
    vec4 clip = shadowProjection * shadowModelView * vec4(playerPos, 1.0);
    vec3 sp = distortShadow(clip.xyz / clip.w) * 0.5 + 0.5;
    float border = 1.5 / float(shadowMapResolution);
    if (any(lessThan(sp, vec3(border))) || any(greaterThan(sp, vec3(1.0 - border)))) return 0.0;
    float shadowDepth = texture(shadowtex1, sp.xy).r;
    float visibility = smoothstep(-0.0003, 0.0003, shadowDepth - sp.z + 0.00035);
    return visibility * (1.0 - smoothstep(shadowDistance * 0.75, shadowDistance * 0.95, length(playerPos.xz)));
}

#endif
