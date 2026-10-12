#ifndef VP_END_SKY
#define VP_END_SKY

#include "/lib/settings.glsl"

#ifndef END_STARS
#define END_STARS 1
#endif

#ifndef END_NEBULA
#define END_NEBULA 1
#endif

// Hash 3D -> 1D
float endHash31(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}

// Hash 3D -> 3D
vec3 endHash33(vec3 p) {
    vec3 q = fract(p * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yxz + 33.33);
    return fract((q.xxy + q.yxx) * q.zyx);
}

// 3D Value Noise com interpolação cúbica suave (Hermite)
float endNoise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f * f * (3.0 - 2.0 * f);

    float n000 = endHash31(i + vec3(0.0, 0.0, 0.0));
    float n100 = endHash31(i + vec3(1.0, 0.0, 0.0));
    float n010 = endHash31(i + vec3(0.0, 1.0, 0.0));
    float n110 = endHash31(i + vec3(1.0, 1.0, 0.0));
    float n001 = endHash31(i + vec3(0.0, 0.0, 1.0));
    float n101 = endHash31(i + vec3(1.0, 0.0, 1.0));
    float n011 = endHash31(i + vec3(0.0, 1.0, 1.0));
    float n111 = endHash31(i + vec3(1.0, 1.0, 1.0));

    return mix(mix(mix(n000, n100, u.x), mix(n010, n110, u.x), u.y),
               mix(mix(n001, n101, u.x), mix(n011, n111, u.x), u.y), u.z);
}

float endNebulaFBM(vec3 p) {
    float n = endNoise3D(p) * 0.62;
    n += endNoise3D(p * 2.15 + vec3(1.7, 3.1, 2.4)) * 0.38;
    return n;
}

// Céu atmosférico base do The End (gradiente místico aroxeado)
vec3 getEndSkyAtmosphere(vec3 dir) {
    // Nadir (abismo profundo abaixo das ilhas): vácuo escuro com leve toque violeta
    vec3 abyssColor = vec3(0.016, 0.005, 0.038);

    // Horizonte: brilho etéreo violeta/magenta
    vec3 horizonColor = vec3(0.105, 0.032, 0.185);
    float horizonBand = exp(-abs(dir.y - 0.05) * 3.6);

    // Zênite (topo do cosmos): roxo cósmico profundo
    vec3 zenithColor = vec3(0.052, 0.016, 0.105);

    vec3 sky = mix(abyssColor, horizonColor, smoothstep(-0.55, 0.04, dir.y));
    sky = mix(sky, zenithColor, smoothstep(0.04, 0.82, dir.y));
    sky += horizonColor * horizonBand * 0.45;

    return sky;
}

// Nebulosa e poeira cósmica interestelar
vec3 getEndNebula(vec3 dir) {
#if END_NEBULA == 1
    float time = frameTimeCounter * 0.003;
    vec3 p = dir * 2.6 + vec3(time * 0.7, time * 0.5, time * 0.3);

    float n1 = endNebulaFBM(p);
    float neb1 = smoothstep(0.40, 0.75, n1);

    vec3 p2 = dir * 3.8 - vec3(time * 0.4, -time * 0.6, time * 0.5) + vec3(4.2, 1.8, 6.5);
    float n2 = endNebulaFBM(p2);
    float neb2 = smoothstep(0.46, 0.82, n2);

    vec3 col1 = mix(vec3(0.06, 0.015, 0.12), vec3(0.22, 0.05, 0.36), neb1) * neb1;
    vec3 col2 = mix(vec3(0.04, 0.012, 0.10), vec3(0.16, 0.04, 0.28), neb2) * neb2 * 1.2;

    float voidMask = smoothstep(-0.45, 0.05, dir.y);
    return (col1 + col2) * voidMask;
#else
    return vec3(0.0);
#endif
}

// Camada celular de estrelas procedurais sem emendas e com cintilação suave
vec3 calcStarCell(vec3 dir, float scale, float densityThreshold, float sizeMultiplier, float twinkleSpeed, bool withCross) {
    vec3 p = dir * scale;
    vec3 cell = floor(p);
    vec3 f = fract(p) - 0.5;

    vec3 rnd = endHash33(cell);
    if (rnd.z < densityThreshold) return vec3(0.0);

    // Posição da estrela contida de forma segura no centro da célula
    vec3 starCenter = (rnd - 0.5) * 0.44;
    float dist = length(f - starCenter);

    float radius = (0.04 + 0.07 * rnd.y) * sizeMultiplier;
    if (dist > radius && !withCross) return vec3(0.0);

    float glow = smoothstep(radius, 0.0, dist);
    glow = glow * glow;

    // Brilho em cruz de difração astronômica para estrelas maiores
    if (withCross) {
        vec3 delta = abs(f - starCenter);
        float arm = max(smoothstep(radius * 2.8, 0.0, delta.x) * smoothstep(radius * 0.35, 0.0, delta.y),
                        smoothstep(radius * 2.8, 0.0, delta.y) * smoothstep(radius * 0.35, 0.0, delta.x));
        glow += arm * 0.5;
    }

    // Cintilação orgânica
    float twinkle = sin(frameTimeCounter * twinkleSpeed + rnd.x * 6.28318) * 0.25 + 0.75;
    float brightness = pow((rnd.z - densityThreshold) / (1.0 - densityThreshold), 1.4) * twinkle;

    // Variação de cor cósmica: branco-gelo, lilás, lavanda suave e ciano cósmico
    vec3 starColor = mix(vec3(0.92, 0.88, 1.0), vec3(0.82, 0.72, 1.0), rnd.x);
    starColor = mix(starColor, vec3(1.0, 0.82, 0.96), rnd.y * 0.6);

    return starColor * glow * brightness;
}

// Campo estelar completo do The End
vec3 getEndStars(vec3 dir) {
#if END_STARS == 1
    // Atenua suavemente no abismo abaixo das ilhas (sensação de profundidade infinita)
    float voidFade = smoothstep(-0.50, -0.05, dir.y);
    if (voidFade <= 0.0001) return vec3(0.0);

    vec3 stars = vec3(0.0);

    // Camada 1: Poeira estelar densa e estrelas de fundo
    stars += calcStarCell(dir, 260.0, 0.70, 0.85, 3.2, false) * 1.6;

    // Camada 2: Estrelas médias cintilantes
    stars += calcStarCell(dir, 130.0, 0.82, 1.15, 2.0, false) * 3.0;

    // Camada 3: Estrelas proeminentes brilhantes com pontas de difração
    stars += calcStarCell(dir, 65.0, 0.94, 1.5, 1.2, true) * 4.5;

    return stars * voidFade;
#else
    return vec3(0.0);
#endif
}

// Céu completo do The End (Base aroxeada + Nebulosa + Estrelas)
vec3 getEndSkyFull(vec3 dir) {
    vec3 sky = getEndSkyAtmosphere(dir);
    sky += getEndNebula(dir);
    sky += getEndStars(dir);
    return sky;
}

#endif
