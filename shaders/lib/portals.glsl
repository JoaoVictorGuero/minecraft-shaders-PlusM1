#ifndef VP_PORTALS
#define VP_PORTALS

bool isPortalMaterial(int id) { return id == 10017 || id == 10018; }

float portalHash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

vec3 endPortalSurface(vec3 worldPos) {
    // End portal geometry has no atlas UVs. Reconstruct a drifting star field.
    vec2 plane = worldPos.xz + worldPos.y * vec2(0.23, 0.37);
    float stars = 0.0;
    for (int layer = 0; layer < 3; ++layer) {
        float scale = 3.5 + float(layer) * 2.7;
        vec2 p = plane * scale + vec2(0.13, -0.09) * frameTimeCounter * (1.0 + float(layer) * 0.3);
        vec2 cell = floor(p);
        vec2 local = fract(p) - 0.5;
        float seed = portalHash(cell + float(layer) * 17.0);
        vec2 center = vec2(portalHash(cell + 3.1), portalHash(cell + 8.7)) * 0.5 - 0.25;
        float radius = 0.035 + seed * 0.065;
        float distanceToStar = length(local - center);
        float glow = exp(-distanceToStar * distanceToStar / (radius * radius));
        stars += glow * smoothstep(0.35, 0.9, seed) / (1.0 + float(layer) * 0.4);
    }
    return vec3(0.005, 0.022, 0.014) + vec3(0.18, 0.85, 0.42) * stars * EMISSIVE_BOOST;
}

// Portal surfaces keep their own emissive colors independently of ambient light.
void renderPortal(vec4 texel, vec3 worldPos, int id) {
    vec4 color = texel;
    if (id == 10018) {
        color = vec4(endPortalSurface(worldPos), 1.0);
    } else {
        if (color.a < 0.01) discard;
        color.rgb *= max(1.0, EMISSIVE_BOOST * 0.65);
    }
    gl_FragData[0] = color;
}
#endif