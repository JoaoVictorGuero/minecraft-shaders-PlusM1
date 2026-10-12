#ifndef VP_WIND
#define VP_WIND
#include "/lib/settings.glsl"
uniform float frameTimeCounter;
uniform float rainStrength;
uniform vec3 cameraPosition;
// Same world-space deformation in terrain and shadow passes.
vec3 foliageWind(vec3 worldPos, int id, float uvY, float midY) {
    if (id < 10000 || id > 10003 || WIND_STRENGTH <= 0.0) return vec3(0.0);
    float anchor = id == 10001 ? 0.42 : (uvY < midY ? 1.0 : 0.0);
    if (id == 10002) anchor = 0.3;
    float phase = dot(worldPos.xz, vec2(0.43, 0.31)) + worldPos.y * 0.17;
    float time = frameTimeCounter * 1.6;
    float gust = 0.65 + 0.35 * sin(time * 0.37 + phase * 0.23);
    vec2 sway = vec2(sin(time + phase), cos(time * 0.83 + phase));
    sway += 0.25 * vec2(sin(time * 2.1 + phase * 1.7), cos(time * 1.8 + phase));
    return vec3(sway.x, 0.0, sway.y * 0.6) * (0.11 * anchor * gust * WIND_STRENGTH * (1.0 + rainStrength * 0.5));
}
#endif
