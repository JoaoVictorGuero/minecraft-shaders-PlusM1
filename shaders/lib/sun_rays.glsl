#ifndef VP_SUN_RAYS
#define VP_SUN_RAYS
#include "/lib/volume_shadows.glsl"

vec3 traceSunRays(vec3 direction, vec3 sunDir, float sceneDistance, float eyeSky) {
    float daylight = smoothstep(0.015, 0.18, sunDir.y);
    float strength = SUN_RAYS * daylight * smoothstep(0.0, 0.45, eyeSky);
    strength *= 1.0 - rainStrength * 0.85;
    if (!vpIsOverworld() || strength <= 0.001) return vec3(0.0);
    float range = min(max(sceneDistance, 0.0), min(64.0, shadowDistance * 0.75));
    float stepLength = range / float(SUN_RAY_STEPS);
    float jitter = fract(52.9829189 * fract(dot(gl_FragCoord.xy, vec2(0.06711056, 0.00583715))));
    float density = 0.007 * FOG_DENSITY;
    float transmittanceStep = exp(-density * stepLength);
    float transmittance = exp(-density * stepLength * (0.25 + jitter * 0.5));
    float scattered = 0.0;
    vec3 origin = gbufferModelViewInverse[3].xyz;
    for (int i = 0; i < SUN_RAY_STEPS; ++i) {
        float distanceToEye = (float(i) + 0.25 + jitter * 0.5) * stepLength;
        vec3 samplePos = origin + direction * distanceToEye;
        scattered += volumeSunVisibility(samplePos) * transmittance;
        transmittance *= transmittanceStep;
    }
    float alignment = clamp(dot(direction, sunDir), -1.0, 1.0);
    float phase = 0.4816 / pow(max(1.5184 - 1.44 * alignment, 0.0784), 1.5);
    phase = 0.15 + 0.16 * min(phase, 8.0);
    return getLightColor(sunDir.y, 0.0) * scattered * (density * stepLength * phase * strength);
}
#endif