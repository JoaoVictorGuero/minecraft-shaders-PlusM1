#ifndef VP_SHADOWS
#define VP_SHADOWS
#include "/lib/shadow_distortion.glsl"
const bool shadowtex1Nearest = true;
float getSoftShadow(vec4 viewSpacePos, vec3 worldNormal, vec3 sunDir, float foliage) {
    if (!vpIsOverworld()) return 1.0;
    float dayF = shadowDayFactor(sunDir.y);
    float ndl = dot(worldNormal, sunDir);
    if (dayF <= 0.0 || (ndl <= 0.01 && foliage < 0.5)) return 1.0;
    vec3 playerPos = (gbufferModelViewInverse * viewSpacePos).xyz;
    float distanceToPlayer = length(playerPos.xz);
    if (distanceToPlayer >= shadowDistance) return 1.0;
    float texelWorld = 2.0 * shadowDistance / float(shadowMapResolution);
    playerPos += worldNormal * texelWorld * (0.35 + 0.65 * (1.0 - max(ndl, 0.0)));
    vec4 clip = shadowProjection * shadowModelView * vec4(playerPos, 1.0);
    vec3 sp = distortShadow(clip.xyz / clip.w) * 0.5 + 0.5;
    float edge = float(SHADOW_FILTER + 1) / float(shadowMapResolution);
    if (any(lessThan(sp, vec3(edge))) || any(greaterThan(sp, vec3(1.0 - edge)))) return 1.0;
    float bias = 0.00035 + (1.0 - max(ndl, 0.0)) * 0.00045;
    float visibility = 0.0;
    for (int x = -SHADOW_FILTER; x <= SHADOW_FILTER; ++x) {
        for (int y = -SHADOW_FILTER; y <= SHADOW_FILTER; ++y) {
            vec2 offset = vec2(x, y) / float(shadowMapResolution);
            visibility += step(sp.z - bias, texture(shadowtex1, sp.xy + offset).r);
        }
    }
    visibility /= float((SHADOW_FILTER * 2 + 1) * (SHADOW_FILTER * 2 + 1));
    visibility = mix(visibility, 1.0, smoothstep(shadowDistance * 0.75, shadowDistance, distanceToPlayer));
    return mix(1.0, visibility, dayF * SHADOW_STRENGTH);
}
#endif
