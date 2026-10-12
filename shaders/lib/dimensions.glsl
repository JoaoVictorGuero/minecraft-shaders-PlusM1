#ifndef VP_DIMENSIONS
#define VP_DIMENSIONS

// Each entry point supplies its dimension; dimension.properties routes Iris
// by registry ID. Never infer the End from skylight or ceiling properties.
#ifndef VP_DIMENSION
#error Missing VP_DIMENSION in shader entry point
#endif
uniform vec3 fogColor;

#include "/lib/end_sky.glsl"

bool vpIsOverworld() { return VP_DIMENSION == 0; }
bool vpIsNether() { return VP_DIMENSION == -1; }
bool vpIsEnd() { return VP_DIMENSION == 1; }

vec3 dimensionSky(vec3 dir) {
    if (vpIsNether()) {
        // The engine blends biome fog colors (including soul/warped biomes).
        // Keep that hue instead of painting every Nether biome orange.
        return max(fogColor, vec3(0.0)) * 0.85 + vec3(0.018, 0.008, 0.004);
    }
    // The End: atmosfera aroxeada com poeira cósmica suave para neblina e horizonte
    return getEndSkyAtmosphere(dir) + getEndNebula(dir) * 0.35;
}

vec3 dimensionAmbient(vec3 normal) {
    if (vpIsNether()) {
        vec3 biomeTint = max(fogColor, vec3(0.0));
        biomeTint /= max(max(biomeTint.r, max(biomeTint.g, biomeTint.b)), 0.001);
        vec3 ambient = mix(vec3(0.32, 0.25, 0.21), biomeTint * 0.32, 0.2);
        return ambient * (0.85 + 0.15 * normal.y);
    }
    // Readable end stone and entities even when the sky lightmap is zero.
    vec3 softPink = vec3(0.39, 0.30, 0.35);
    vec3 vividPink = vec3(0.82, 0.19, 0.55);
    vec3 ambient = mix(softPink, vividPink, END_PINK_LIGHT);
    return ambient * (0.82 + 0.18 * normal.y);
}

float dimensionFog(float distanceToEye, float renderDistance) {
    float density = vpIsNether() ? 0.009 : 0.0025;
    float haze = 1.0 - exp(-distanceToEye * density * FOG_DENSITY);
    // Always hide the chunk boundary, even with a low fog density setting.
    float edge = smoothstep(renderDistance * 0.55, renderDistance * 0.98, distanceToEye);
    return max(haze, edge);
}

vec3 worldSunDirection(mat3 viewToWorld, vec3 position) {
    // Non-solar dimensions can supply a zero/irrelevant celestial position.
    if (!vpIsOverworld()) return vec3(0.0, 1.0, 0.0);
    vec3 direction = viewToWorld * position;
    return direction / max(length(direction), 0.0001);
}

#endif
