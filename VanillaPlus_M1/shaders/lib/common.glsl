// =====================================================================
//  VanillaPlus M1 - Biblioteca compartilhada
//  Paleta de cores, céu e iluminação usados por TODOS os shaders.
//  Ajuste aqui e o pack inteiro muda junto, sem costuras.
// =====================================================================
#ifndef VP_COMMON
#define VP_COMMON

#include "/lib/settings.glsl"

uniform float frameTimeCounter;

#include "/lib/dimensions.glsl"

// Dynamic light (Iris)
uniform int heldBlockLightValue;   // Nível de luz do item na mão principal
uniform int heldBlockLightValue2;  // Nível de luz do item na mão secundária
uniform int heldItemId;            // ID do item.properties (mão principal)
uniform int heldItemId2;           // ID do item.properties (mão secundária)

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

// ---------- CICLO DO DIA ----------
// sunHeight = Y do sol em World Space (-1 .. 1)
float dayMix(float sh)   { return smoothstep(0.0, 0.3, sh); }          // 0 = pôr do sol, 1 = dia
float nightMix(float sh) { return 1.0 - smoothstep(-0.25, 0.0, sh); }  // 1 = noite
float shadowDayFactor(float sh) { return smoothstep(-0.05, 0.15, sh); }

vec3 timeBlend(vec3 day, vec3 sunset, vec3 night, float sh) {
    vec3 c = mix(sunset, day, dayMix(sh));
    return mix(c, night, nightMix(sh));
}

vec2 remapLightmap(vec2 lm) {
    // O lightmap do Minecraft vai de 1/32 a 31/32. Normaliza pra 0..1
    return clamp((lm - 1.0 / 32.0) * (32.0 / 30.0), 0.0, 1.0);
}

// ---------- PALETA DE LUZ ----------
vec3 getLightColor(float sh, float rain) {
    if (!vpIsOverworld()) return vec3(0.0);
    vec3 c = timeBlend(vec3(1.22, 0.96, 0.72),   // sol dourado
                       vec3(1.20, 0.57, 0.27),   // entardecer alaranjado
                       vec3(0.11, 0.16, 0.30),   // luar
                       sh);
    return mix(c, vec3(luma(c)) * 0.55, rain * 0.75);
}

vec3 getAmbientColor(float sh, float rain) {
    vec3 c = timeBlend(vec3(0.48, 0.59, 0.76),   // sombras azuladas sob o sol quente
                       vec3(0.52, 0.40, 0.57),   // contraste violeta no entardecer
                       vec3(0.15, 0.17, 0.25),
                       sh);
    return mix(c, vec3(luma(c)) * 0.85, rain * 0.6);
}

// ---------- CÉU ----------
vec3 getSkyColor(vec3 dir, vec3 sunDir, float rain) {
    if (!vpIsOverworld()) {
        if (vpIsEnd()) return getEndSkyFull(dir);
        return dimensionSky(dir);
    }
    float sh = sunDir.y;
    float up = clamp(dir.y, 0.0, 1.0);
    // Fade the azimuth-dependent sunset to zero BEFORE reaching the zenith.
    // Normalizing dir.xz at the zenith caused the purple wedge in the sky.
    float horizontal = length(dir.xz);
    float sunHorizontal = length(sunDir.xz);
    float alignment = dot(dir.xz, sunDir.xz) / max(horizontal * sunHorizontal, 0.001);
    float facing = pow(max(alignment, 0.0), 3.0);
    float sunsetBand = (1.0 - smoothstep(0.02, 0.55, up)) * smoothstep(0.0, 0.2, horizontal);
    vec3 zenith = timeBlend(vec3(0.10, 0.36, 0.78), vec3(0.16, 0.23, 0.43),
                           vec3(0.012, 0.022, 0.052), sh);
    vec3 horizon = timeBlend(vec3(0.68, 0.78, 0.94), vec3(0.76, 0.44, 0.40),
                            vec3(0.055, 0.085, 0.145), sh);
    float twilight = (1.0 - dayMix(sh)) * (1.0 - nightMix(sh));
    vec3 sky = mix(horizon, zenith, pow(up, 0.6));
    sky = mix(sky, vec3(1.0, 0.36, 0.12), facing * sunsetBand * twilight * 0.85);
    return mix(sky, vec3(luma(sky)) * vec3(0.86, 0.92, 1.0) * 0.8, rain * 0.8);
}

vec3 getSunGlow(vec3 dir, vec3 sunDir, float rain) {
    if (!vpIsOverworld()) return vec3(0.0);
    float d = max(dot(dir, sunDir), 0.0);
    float vis = smoothstep(-0.12, 0.02, sunDir.y);
    vec3 col = mix(vec3(1.0, 0.40, 0.12), vec3(1.0, 0.78, 0.50), smoothstep(0.0, 0.35, sunDir.y));
    float g = pow(d, 6.0) * 0.35 + pow(d, 48.0) * 0.5;
    return col * g * vis * (1.0 - rain * 0.85);
}

vec3 getMoonGlow(vec3 dir, vec3 sunDir, float rain) {
    if (!vpIsOverworld()) return vec3(0.0);
    float d = max(dot(dir, -sunDir), 0.0);
    return vec3(0.35, 0.45, 0.70) * pow(d, 24.0) * 0.15 * nightMix(sunDir.y) * (1.0 - rain);
}

// ---------- DYNAMIC LIGHT ----------
vec3 heldLightColor(int id) {
    if (id == 20001) return vec3(0.35, 0.80, 1.00); // Alma (azul)
    if (id == 20002) return vec3(1.00, 0.22, 0.12); // Redstone (vermelho)
    if (id == 20003) return vec3(0.80, 0.92, 1.00); // Sea lantern / end rod (branco frio)
    if (id == 20004) return vec3(1.00, 0.82, 0.50); // Glowstone / abóbora (amarelo)
    if (id == 20005) return vec3(1.00, 0.42, 0.12); // Lava / magma (laranja)
    if (id == 20006) return vec3(0.75, 0.45, 1.00); // Ametista / crying obsidian (roxo)
    return TORCH_COLOR;                           // Tocha comum (âmbar)
}

int heldLightLevel(int level, int id) {
    if (id == 20005) return max(level, 15); // Balde de lava brilha mesmo não sendo bloco
    if (id == 20006) return max(level, 10);
    return level;
}

// Retorna rgb = cor, a = intensidade (0..1, mesmo formato do lightmap)
// viewPos = posição em View Space, n = normal em World Space
vec4 getHandLight(vec3 viewPos, vec3 n, mat3 viewToWorld) {
    float L1 = float(heldLightLevel(heldBlockLightValue,  heldItemId));
    float L2 = float(heldLightLevel(heldBlockLightValue2, heldItemId2));
    if (max(L1, L2) <= 0.0 || DYNAMIC_LIGHT <= 0.0) return vec4(0.0);
    float dist = length(viewPos);
    float h1 = clamp(1.0 - dist / (L1 + 0.5), 0.0, 1.0) * (L1 / 15.0);
    float h2 = clamp(1.0 - dist / (L2 + 0.5), 0.0, 1.0) * (L2 / 15.0);
    #if DYNAMIC_FLICKER == 1
    float flick = 0.96 + 0.025 * sin(frameTimeCounter * 11.0) + 0.015 * sin(frameTimeCounter * 23.7 + 1.3);
    if (heldItemId == 20000 || heldItemId == 20001 || heldItemId == 20005) h1 *= flick;
    if (heldItemId2 == 20000 || heldItemId2 == 20001 || heldItemId2 == 20005) h2 *= flick;
    #endif
    float w1 = h1 * h1 * h1;
    float w2 = h2 * h2 * h2;
    vec3 col = (heldLightColor(heldItemId) * w1 + heldLightColor(heldItemId2) * w2) / max(w1 + w2, 0.00001);
    vec3 toCam = -(viewToWorld * viewPos) / max(dist, 0.001);
    float h = max(h1, h2) * (0.55 + 0.45 * max(dot(n, toCam), 0.0));
    return vec4(col, clamp(h * DYNAMIC_LIGHT, 0.0, 1.0));
}

// ---------- ILUMINAÇÃO DE CENA ----------
// n = normal em World Space, lmRaw = lmcoord bruto, shadow = 0..1, foliage = 0/1
// hand = resultado de getHandLight (vec4(0) se não quiser dynamic light)
vec3 getSceneLighting(vec3 n, vec3 sunDir, vec2 lmRaw, float shadow, float foliage, float rain, vec4 hand) {
    float sh = sunDir.y;
    vec2 lm = remapLightmap(lmRaw);

    vec3 direct = vec3(0.0);
    vec3 ambient;
    if (vpIsOverworld()) {
        // Luz direcional (sol de dia, plana de noite)
        vec3 lightDir = sh >= 0.0 ? sunDir : -sunDir;
        float NdotL = max(dot(n, lightDir), 0.0);
        NdotL = mix(NdotL, 0.45 + 0.55 * NdotL, foliage); // Folhas deixam a luz atravessar
        float directional = mix(NIGHT_FLAT_LIGHT, NdotL, shadowDayFactor(sh));

        // Sol só chega onde se vê o céu (debaixo de árvores/telhados escurece suave)
        float skyDirect = lm.y * lm.y * lm.y;
        direct = getLightColor(sh, rain) * directional * shadow * skyDirect * (1.0 - rain * 0.6);
        // Gentle transmission through leaves; blocked sunlight stays blocked.
        float transmission = foliage * pow(max(dot(-n, lightDir), 0.0), 2.0);
        direct += getLightColor(sh, rain) * transmission * 0.18 * shadow * skyDirect * shadowDayFactor(sh);

        // Luz ambiente do céu (topo mais claro, embaixo mais escuro - bem suave)
        float dome = 0.76 + 0.24 * n.y;
        ambient = getAmbientColor(sh, rain) * (lm.y * lm.y) * dome;
        vec3 bounce = vec3(0.15, 0.096, 0.052) * (1.0 - max(n.y, 0.0));
        ambient += bounce * lm.y * lm.y * dayMix(sh) * (1.0 - rain * 0.5);
    } else {
        ambient = dimensionAmbient(n);
    }

    // Tochas: luz quente com queda natural, mais discreta sob o sol
    float bl = lm.x;
    vec3 blockTorch = TORCH_COLOR * (bl * bl * bl * TORCH_STRENGTH + bl * 0.06);
    vec3 torch = blockTorch;

    // Dynamic light: soma com a luz dos blocos sem estourar (pega o maior)
    float hl = hand.a;
    vec3 handTorch = hand.rgb * (hl * hl * hl * TORCH_STRENGTH + hl * 0.06);
    float blockEnergy = luma(blockTorch);
    float handEnergy = luma(handTorch);
    float overlapScale = 1.0 - 0.75 * min(blockEnergy, handEnergy) / max(blockEnergy + handEnergy, 0.00001);
    torch = (blockTorch + handTorch) * overlapScale;

    float dayDim = vpIsOverworld() ? 1.0 - 0.5 * dayMix(sh) * lm.y : 1.0;
    torch *= dayDim;

    vec3 total = ambient + direct + torch + vec3(MIN_CAVE_LIGHT, MIN_CAVE_LIGHT, MIN_CAVE_LIGHT * 1.3);


    return total;
}

#endif
