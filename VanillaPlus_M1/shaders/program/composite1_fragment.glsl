uniform sampler2D colortex0;
uniform sampler2D colortex2; // Half-resolution sunlight scattering
uniform sampler2D depthtex0;

#include "/lib/settings.glsl"

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16F;
*/
const vec4 colortex0ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex1ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform float far;
uniform float rainStrength;
uniform float blindness;
uniform int isEyeInWater;     // 0 = ar, 1 = água, 2 = lava, 3 = neve em pó
uniform ivec2 eyeBrightnessSmooth;

in vec2 texcoord;

#include "/lib/common.glsl"
#include "/lib/water_optics.glsl"
#include "/lib/clouds.glsl"
#include "/lib/aurora.glsl"
#include "/lib/underwater_rays.glsl"
uniform sampler2D colortex5;

vec3 getViewPos(vec2 coord, float depth) {
    vec4 p = gbufferProjectionInverse * vec4(vec3(coord, depth) * 2.0 - 1.0, 1.0);
    return p.xyz / p.w;
}

float hash13(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}

// Estrelas procedurais (o céu vanilla foi desligado no skybasic)
vec3 getStars(vec3 dir, float sh, float rain) {
    if (!vpIsOverworld()) return vec3(0.0);
    float vis = (1.0 - smoothstep(-0.22, -0.06, sh)) * (1.0 - rain) * smoothstep(0.0, 0.25, dir.y);
    if (vis <= 0.0) return vec3(0.0);
    vec3 cell = floor(dir * 220.0);
    float h = hash13(cell);
    float star = smoothstep(0.9975, 1.0, h);
    float tint = hash13(cell + 17.0);
    vec3 col = mix(vec3(0.75, 0.85, 1.0), vec3(1.0, 0.9, 0.75), tint);
    return col * star * 2.5 * vis;
}

vec3 getWaterFog(vec3 dir, float sh) {
    if (!vpIsOverworld()) {
        vec3 deep = vpIsNether() ? vec3(0.055, 0.035, 0.02) : vec3(0.04, 0.012, 0.10);
        vec3 surface = vpIsNether() ? vec3(0.18, 0.10, 0.045) : vec3(0.18, 0.06, 0.36);
        return mix(deep, surface, clamp(dir.y, -1.0, 1.0) * 0.5 + 0.5);
    }
    vec3 deep    = timeBlend(vec3(0.008, 0.085, 0.12), vec3(0.05, 0.05, 0.14), vec3(0.0, 0.008, 0.035), sh);
    vec3 surface = timeBlend(vec3(0.08, 0.38, 0.43), vec3(0.20, 0.15, 0.28), vec3(0.01, 0.04, 0.08), sh);
    return mix(deep, surface, clamp(dir.y, -1.0, 1.0) * 0.5 + 0.5);
}

/* DRAWBUFFERS:01 */

// Bilinear interpolation weighted by scene depth prevents half-resolution
// sunlight from bleeding over the hand, nearby blocks or sky silhouettes.
vec3 getSunRays(vec2 uv, float surfaceDistance) {
    ivec2 size = textureSize(colortex2, 0);
    vec2 p = uv * vec2(size) - 0.5;
    ivec2 base = ivec2(floor(p));
    vec2 f = fract(p);
    vec3 light = vec3(0.0);
    float weightSum = 0.0;
    for (int y = 0; y < 2; ++y) {
        for (int x = 0; x < 2; ++x) {
            ivec2 coord = clamp(base + ivec2(x, y), ivec2(0), size - 1);
            vec4 sampleRay = texelFetch(colortex2, coord, 0);
            vec2 bilinear = mix(1.0 - f, f, vec2(x, y));
            float weight = bilinear.x * bilinear.y;
            weight *= exp(-abs(sampleRay.a - surfaceDistance) / max(0.8, surfaceDistance * 0.06));
            light += sampleRay.rgb * weight;
            weightSum += weight;
        }
    }
    return light / max(weightSum, 0.00001);
}

void main() {
    vec2 sceneUV = texcoord;
    float depth = texture(depthtex0, sceneUV).r;
    vec3 viewPos = getViewPos(sceneUV, depth);
    if (isEyeInWater == 1 && UNDERWATER_DISTORTION > 0.0 && depth > 0.56 && depth < 1.0) {
        float t = frameTimeCounter * 0.7;
        vec2 wave = vec2(sin(texcoord.y * 24.0 + t) + sin(texcoord.x * 17.0 - t * 1.3),
                         cos(texcoord.x * 21.0 + t * 0.8) + sin(texcoord.y * 19.0 - t));
        vec2 pixel = 1.0 / vec2(textureSize(colortex0, 0));
        float distanceFade = smoothstep(1.0, 6.0, length(viewPos));
        vec2 warpedUV = clamp(sceneUV + wave * pixel * UNDERWATER_DISTORTION * distanceFade,
                              pixel * 0.5, 1.0 - pixel * 0.5);
        float warpedDepth = texture(depthtex0, warpedUV).r;
        vec3 warpedPos = getViewPos(warpedUV, warpedDepth);
        // Reject foreground/sky crossings so silhouettes stay clean.
        if (warpedDepth > 0.56 && warpedDepth < 1.0 &&
            abs(length(warpedPos) - length(viewPos)) < max(0.3, length(viewPos) * 0.025)) {
            sceneUV = warpedUV;
            depth = warpedDepth;
            viewPos = warpedPos;
        }
    }
    vec3 color = texture(colortex0, sceneUV).rgb;
    vec3 worldDir = normalize(mat3(gbufferModelViewInverse) * viewPos);
    vec3 sunDir = worldSunDirection(mat3(gbufferModelViewInverse), sunPosition);
    float sh = sunDir.y;

    // Quanto de céu o jogador está vendo (0 = caverna, 1 = ao ar livre)
    float eyeSky = vpIsOverworld() ? clamp(float(eyeBrightnessSmooth.y) / 240.0, 0.0, 1.0) : 1.0;

    vec3 skyDir = vec3(worldDir.x, max(worldDir.y, 0.0), worldDir.z);
    vec3 sky = getSkyColor(skyDir, sunDir, rainStrength);
    vec3 sunGlow = getSunGlow(worldDir, sunDir, rainStrength);

    if (depth < 1.0) {
        float dist = length(viewPos);

        if (isEyeInWater == 1) {
            vec3 transmission = waterTransmission(dist);
            vec3 waterFog = getWaterFog(worldDir, sh) * (0.22 + 0.78 * eyeSky);
            color = color * transmission + waterFog * (1.0 - transmission);
            // Sun shafts are integrated separately through the visible water segment.
        } else if (isEyeInWater == 2) {
            color = mix(color, vec3(1.2, 0.35, 0.05), 1.0 - exp(-dist * 0.6));
        } else if (isEyeInWater == 3) {
            color = mix(color, vec3(0.7, 0.8, 0.9), 1.0 - exp(-dist * 0.9));
        } else if (!vpIsOverworld()) {
            color = mix(color, dimensionSky(worldDir), dimensionFog(dist, far));
        } else {
            // Neblina atmosférica: começa suave, fecha no limite do render, mais densa na chuva
            float start = mix(far * 0.35, far * 0.1, rainStrength);
            float fog = smoothstep(start, far * 0.98, dist * FOG_DENSITY);
            fog = max(fog, (1.0 - exp(-dist * 0.003 * FOG_DENSITY)) * 0.25); // leve névoa aérea (profundidade)

            // Em cavernas a neblina não fica azul-céu
            vec3 fogCol = sky + sunGlow * 0.6;
            fogCol = mix(vec3(0.02, 0.022, 0.03), fogCol, smoothstep(0.0, 0.6, eyeSky));
            color = mix(color, fogCol, fog);
        }
    } else {
        if (isEyeInWater == 1) {
            color = getWaterFog(worldDir, sh) * (0.22 + 0.78 * eyeSky);
        } else if (isEyeInWater >= 2) {
            color = isEyeInWater == 2 ? vec3(1.2, 0.35, 0.05) : vec3(0.7, 0.8, 0.9);
        } else if (!vpIsOverworld()) {
            // Replace the background instead of adding the vanilla skybox.
            if (vpIsEnd()) {
                color = getEndSkyFull(worldDir) + getAurora(worldDir);
            } else {
                color = dimensionSky(worldDir);
            }
        } else {
            // Celestial textures are composed before clouds, which attenuate them.
            vec3 skyFull = getSkyColor(worldDir, sunDir, rainStrength);
            // Abaixo do horizonte escurece levemente (sem "chão" azul brilhante)
            skyFull *= mix(1.0, 0.6, (1.0 - smoothstep(-0.3, 0.0, worldDir.y)));
            color = skyFull + sunGlow + getMoonGlow(worldDir, sunDir, rainStrength)
                  + getStars(worldDir, sh, rainStrength) + color;
        }
    }

    #if CLOUD_STYLE != 0
    if (isEyeInWater == 0 && vpIsOverworld()) {
        vec3 origin = cameraPosition + gbufferModelViewInverse[3].xyz;
        vec2 interval = cloudInterval(origin, worldDir);
        float sceneDistance = depth >= 1.0 ? cloudRange : length(viewPos);
        if (interval.y > interval.x && sceneDistance > interval.x) {
            vec4 clouds;
            if (sceneDistance < interval.y) {
                clouds = traceClouds(origin, worldDir, sunDir, rainStrength, sceneDistance);
            } else {
                vec2 cloudTexel = 0.5 / vec2(textureSize(colortex5, 0));
                clouds = texture(colortex5, clamp(sceneUV, cloudTexel, 1.0 - cloudTexel));
            }
            color = color * (1.0 - clouds.a) + clouds.rgb;
        }
    }
    #endif
    if (isEyeInWater == 0 && vpIsOverworld() && SUN_RAYS > 0.0 && depth > 0.56) {
        float surfaceDistance = depth >= 1.0 ? far : length(viewPos);
        color += getSunRays(sceneUV, surfaceDistance);
    }
    if (isEyeInWater == 1 && vpIsOverworld() && UNDERWATER_RAYS > 0.0 && depth > 0.56) {
        float waterDistance = depth >= 1.0 ? 32.0 : length(viewPos);
        color += traceUnderwaterRays(worldDir, sunDir, waterDistance, eyeSky);
    }
    color = mix(color, vec3(0.0), blindness);

    // Bright pass para o bloom (só o que é realmente brilhante)
    float l = luma(color);
    vec3 bright = color * (max(l - 1.0, 0.0) / max(l, 0.001));

    gl_FragData[0] = vec4(color, 1.0);
    gl_FragData[1] = vec4(bright, 1.0);
}
