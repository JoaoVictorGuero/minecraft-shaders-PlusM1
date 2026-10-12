#ifndef VP_AURORA
#define VP_AURORA

#include "/lib/common.glsl"

float auroraNoise(float x) {
    float cell = floor(x);
    float f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    vec2 h = fract(vec2(cell, cell + 1.0) * 0.1031);
    h *= h + 33.33;
    h *= h + h;
    return mix(fract(h.x), fract(h.y), f);
}

// Distant luminous curtains in world directions, so turning the camera does
// not move the effect. No azimuth/atan seam at the zenith or across north.
vec3 getAurora(vec3 dir) {
#if AURORA == 1 && VP_DIMENSION == 1
    // The End has no day/night or weather cycle; only fade at the horizon.
    float visibility = smoothstep(0.025, 0.18, dir.y);
    if (visibility <= 0.001 || AURORA_STRENGTH <= 0.0) return vec3(0.0);

    float time = frameTimeCounter * 0.035 * AURORA_SPEED;
    vec2 slope = dir.xz / max(dir.y, 0.025);
    // Broaden undersampled slices near the horizon, conserving brightness.
    float width = 0.14 + length(slope) * 0.05;
    vec3 light = vec3(0.0);
    for (int i = 0; i < 16; ++i) {
        float height = (float(i) + 0.5) / 16.0;
        vec2 p = slope * (0.8 + height * 1.6);
        float fold = sin(p.x * 0.85 + time) * 0.65
                   + sin(p.x * 1.9 - time * 0.7) * 0.22;
        float ribbonA = (p.y + 2.4 + fold) / width;
        float ribbonB = (p.y + 4.3 - fold * 0.8) / (width * 1.3);
        float curtains = exp2(-ribbonA * ribbonA) + exp2(-ribbonB * ribbonB) * 0.65;
        // Soft irregular wisps instead of evenly spaced, high-contrast bars.
        float rays = 0.72 + 0.28 * auroraNoise(p.x * 9.0 - time * 0.3);
        float patches = 0.65 + 0.35 * sin(p.x * 0.6 + time * 0.4);
        float envelope = smoothstep(0.0, 0.12, height) * pow(1.0 - height, 0.65);
        vec3 tint = mix(vec3(0.40, 0.15, 0.90), vec3(0.15, 0.65, 0.95), smoothstep(0.15, 0.55, height));
        tint = mix(tint, vec3(0.90, 0.22, 0.85), smoothstep(0.55, 1.0, height));
        light += tint * curtains * rays * patches * envelope * (0.10 / width);
    }
    return light * visibility * AURORA_STRENGTH * 0.45;
#else
    return vec3(0.0);
#endif
}

#endif
