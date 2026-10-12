#ifndef VP_CLOUDS
#define VP_CLOUDS

uniform vec3 cameraPosition;

#if CLOUD_STYLE == 2
const float cloudThickness = 24.0;
const float cloudRange = 1400.0;
#else
const float cloudThickness = 64.0;
const float cloudRange = 3600.0;
#endif

float cloudHash(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}

float cloudNoise(vec3 p) {
    vec3 cell = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(cloudHash(cell), cloudHash(cell + vec3(1,0,0)), f.x),
                   mix(cloudHash(cell + vec3(0,1,0)), cloudHash(cell + vec3(1,1,0)), f.x), f.y),
               mix(mix(cloudHash(cell + vec3(0,0,1)), cloudHash(cell + vec3(1,0,1)), f.x),
                   mix(cloudHash(cell + vec3(0,1,1)), cloudHash(cell + vec3(1,1,1)), f.x), f.y), f.z);
}

vec3 cloudAmbient(float sh, float rain) {
    return timeBlend(vec3(0.60, 0.69, 0.84), vec3(0.57, 0.39, 0.48),
                     vec3(0.085, 0.12, 0.19), sh) * (1.0 - rain * 0.25);
}

vec2 cloudWind() {
    return frameTimeCounter * CLOUD_SPEED * vec2(0.7, 0.22);
}

vec2 cloudInterval(vec3 origin, vec3 dir) {
    if (abs(dir.y) < 0.0001) {
        if (origin.y <= CLOUD_HEIGHT || origin.y >= CLOUD_HEIGHT + cloudThickness) return vec2(0.0);
        return vec2(0.0, cloudRange);
    }
    vec2 hits = (vec2(CLOUD_HEIGHT, CLOUD_HEIGHT + cloudThickness) - origin.y) / dir.y;
    return vec2(max(min(hits.x, hits.y), 0.0), min(max(hits.x, hits.y), cloudRange));
}

float cloudDensity(vec3 p, float rain) {
    float h = (p.y - CLOUD_HEIGHT) / cloudThickness;
    if (h <= 0.0 || h >= 1.0) return 0.0;
    vec3 wind = vec3(cloudWind().x, 0.0, cloudWind().y);
    vec3 q = (p + wind) * vec3(0.008, 0.012, 0.008);
    float shape = cloudNoise(q) * 0.7 + cloudNoise(q * 2.07 + vec3(17.3)) * 0.3;
    float coverage = min(CLOUD_COVERAGE + rain * 0.2, 0.95);
    float threshold = mix(0.72, 0.3, coverage);
    float profile = smoothstep(0.0, 0.16, h) * (1.0 - smoothstep(0.45, 1.0, h));
    return smoothstep(threshold, threshold + 0.18, shape) * profile;
}

// Smooth volumetric clouds. Only this style uses density ray marching.
vec4 traceRealisticClouds(vec3 origin, vec3 dir, vec3 sunDir, float rain, float sceneDistance) {
    vec2 segment = cloudInterval(origin, dir);
    segment.y = min(segment.y, sceneDistance);
    if (segment.y <= segment.x) return vec4(0.0);
    float stepSize = (segment.y - segment.x) / float(CLOUD_STEPS);
    vec3 lightDir = sunDir.y >= 0.0 ? sunDir : -sunDir;
    float forwardGlow = pow(max(dot(dir, lightDir), 0.0), 12.0);
    vec3 direct = getLightColor(sunDir.y, rain);
    vec3 ambient = cloudAmbient(sunDir.y, rain);
    vec4 result = vec4(0.0);
    for (int i = 0; i < CLOUD_STEPS; ++i) {
        float distanceAlongRay = segment.x + (float(i) + 0.5) * stepSize;
        vec3 p = origin + dir * distanceAlongRay;
        float density = cloudDensity(p, rain);
        if (density < 0.001) continue;
        float h = clamp((p.y - CLOUD_HEIGHT) / cloudThickness, 0.0, 1.0);
        float shadowDensity = cloudDensity(p + lightDir * 18.0, rain);
        shadowDensity += cloudDensity(p + lightDir * 42.0, rain) * 0.5;
        float sunlight = exp(-shadowDensity * 2.5);
        float silverLining = pow(1.0 - density, 2.0) * forwardGlow;
        vec3 lighting = ambient * (0.60 + 0.40 * h)
                      + direct * sunlight * (0.60 + silverLining * 1.35);
        vec3 atmosphere = getSkyColor(dir, sunDir, rain);
        lighting = mix(lighting, atmosphere, 1.0 - exp(-distanceAlongRay * 0.00035));
        float horizonFade = 1.0 - smoothstep(cloudRange * 0.65, cloudRange, distanceAlongRay);
        float opacity = 1.0 - exp(-density * stepSize * 0.075 * horizonFade);
        float weight = (1.0 - result.a) * opacity;
        result.rgb += lighting * weight;
        result.a += weight;
        if (result.a > 0.985) break;
    }
    return result;
}

#if CLOUD_STYLE == 2
float cloudNoise2(vec2 p) {
    vec2 c = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(cloudHash(vec3(c, 0.0)), cloudHash(vec3(c + vec2(1, 0), 0.0)), f.x),
               mix(cloudHash(vec3(c + vec2(0, 1), 0.0)), cloudHash(vec3(c + vec2(1, 1), 0.0)), f.x), f.y);
}

// A continuous weather field sampled on a 32-block grid makes connected,
// square-edged islands. Their tops form three discrete, six-block terraces.
float vanillaCloudHeight(vec2 cell, float rain) {
    float shape = cloudNoise2(cell * 0.19) * 0.8
                + cloudNoise2(cell * 0.51 + vec2(17.3)) * 0.2;
    float coverage = min(CLOUD_COVERAGE + rain * 0.2, 0.95);
    float threshold = mix(0.78, 0.36, coverage);
    if (shape < threshold) return 0.0;
    return 12.0 + floor(smoothstep(threshold, threshold + 0.3, shape) * 2.99) * 6.0;
}

vec4 traceEnhancedClouds(vec3 origin, vec3 dir, vec3 sunDir, float rain, float sceneDistance) {
    vec2 segment = cloudInterval(origin, dir);
    segment.y = min(segment.y, sceneDistance);
    if (segment.y <= segment.x) return vec4(0.0);

    // Traverse exact cell boundaries instead of sampling: faces remain square
    // at every angle and thin silhouettes cannot fall between march samples.
    vec2 shiftedOrigin = origin.xz + cloudWind();
    vec2 cell = floor((shiftedOrigin + dir.xz * (segment.x + 0.001)) / 32.0);
    vec2 directionSign = sign(dir.xz);
    vec2 nextEdge = (cell + step(vec2(0.0), dir.xz)) * 32.0;
    vec2 nextHit = vec2(1e20);
    vec2 delta = vec2(1e20);
    if (abs(dir.x) > 0.000001) {
        nextHit.x = (nextEdge.x - shiftedOrigin.x) / dir.x;
        delta.x = 32.0 / abs(dir.x);
    }
    if (abs(dir.z) > 0.000001) {
        nextHit.y = (nextEdge.y - shiftedOrigin.y) / dir.z;
        delta.y = 32.0 / abs(dir.z);
    }
    vec3 lightDir = sunDir.y >= 0.0 ? sunDir : -sunDir;
    vec3 direct = getLightColor(sunDir.y, rain);
    vec3 ambient = cloudAmbient(sunDir.y, rain);
    vec3 atmosphere = getSkyColor(dir, sunDir, rain);
    vec3 entryNormal = vec3(0.0, dir.y >= 0.0 ? -1.0 : 1.0, 0.0);
    vec4 result = vec4(0.0);
    bool connected = false;
    vec3 surfaceLighting = vec3(0.0);
    float surfaceFade = 1.0;
    float t = segment.x;
    // 1400 * sqrt(2) / 32 < 62 crossings, plus the initial cell.
    for (int i = 0; i < 64; ++i) {
        float cellEnd = min(min(nextHit.x, nextHit.y), segment.y);
        float height = vanillaCloudHeight(cell, rain);
        bool filledToEdge = false;
        if (height > 0.0) {
            float hitStart = t;
            float hitEnd = cellEnd;
            vec3 normal = entryNormal;
            if (abs(dir.y) > 0.000001) {
                vec2 slab = (vec2(CLOUD_HEIGHT, CLOUD_HEIGHT + height) - origin.y) / dir.y;
                float slabStart = min(slab.x, slab.y);
                hitEnd = min(hitEnd, max(slab.x, slab.y));
                if (slabStart >= hitStart) {
                    hitStart = slabStart;
                    normal = vec3(0.0, dir.y > 0.0 ? -1.0 : 1.0, 0.0);
                }
            } else if (origin.y < CLOUD_HEIGHT || origin.y > CLOUD_HEIGHT + height) {
                hitEnd = hitStart;
            }
            if (hitEnd > hitStart) {
                // Adjacent occupied cells are one cloud: internal grid faces
                // must not get fresh surface shading or show bright seams.
                if (!connected || hitStart > t + 0.0001) {
                    vec3 p = origin + dir * hitStart;
                    vec3 probe = p + lightDir * 32.0;
                    float neighborHeight = vanillaCloudHeight(floor((probe.xz + cloudWind()) / 32.0), rain);
                    float sunlight = (neighborHeight > 0.0 && probe.y > CLOUD_HEIGHT
                        && probe.y < CLOUD_HEIGHT + neighborHeight) ? 0.6 : 1.0;
                    float faceLight = max(dot(normal, lightDir), 0.0);
                    surfaceLighting = ambient * (0.78 + 0.22 * normal.y)
                                    + direct * (0.22 + 0.78 * faceLight) * sunlight;
                    surfaceLighting = mix(surfaceLighting, atmosphere, 1.0 - exp(-hitStart * 0.00065));
                    surfaceFade = 1.0 - smoothstep(cloudRange * 0.7, cloudRange, hitStart);
                }
                float opacity = 1.0 - exp(-(hitEnd - hitStart) * 0.32 * surfaceFade);
                float weight = (1.0 - result.a) * opacity;
                result.rgb += surfaceLighting * weight;
                result.a += weight;
                filledToEdge = hitEnd >= cellEnd - 0.0001;
                if (result.a > 0.985) break;
            }
        }
        connected = filledToEdge;
        if (cellEnd >= segment.y) break;
        bool crossX = nextHit.x <= nextHit.y;
        bool crossZ = nextHit.y <= nextHit.x;
        if (crossX) {
            cell.x += directionSign.x;
            nextHit.x += delta.x;
            entryNormal = vec3(-directionSign.x, 0.0, 0.0);
        }
        if (crossZ) {
            cell.y += directionSign.y;
            nextHit.y += delta.y;
            if (!crossX) entryNormal = vec3(0.0, 0.0, -directionSign.y);
        }
        t = cellEnd;
    }
    return result;
}
#endif

// Premultiplied RGB + opacity, shared by the half-resolution sky pass and
// depth-clipped foreground pass. Both styles work above and inside the layer.
vec4 traceClouds(vec3 origin, vec3 dir, vec3 sunDir, float rain, float sceneDistance) {
    if (!vpIsOverworld()) return vec4(0.0);
#if CLOUD_STYLE == 1
    return traceRealisticClouds(origin, dir, sunDir, rain, sceneDistance);
#elif CLOUD_STYLE == 2
    return traceEnhancedClouds(origin, dir, sunDir, rain, sceneDistance);
#else
    return vec4(0.0);
#endif
}

#endif
