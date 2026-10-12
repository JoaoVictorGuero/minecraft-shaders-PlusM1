#ifndef VP_WATER_OPTICS
#define VP_WATER_OPTICS

// Animated light interference, anchored to blocks instead of the screen.
float waterCaustics(vec3 position) {
    vec2 p = position.xz * 1.7 + position.y * vec2(0.18, -0.13);
    float t = frameTimeCounter * 0.55;
    vec2 warp = vec2(sin(p.y * 0.7 + t), cos(p.x * 0.8 - t)) * 0.6;
    p += warp;
    float a = sin(p.x + p.y * 0.55 + t);
    float b = sin(p.y - p.x * 0.45 - t * 0.8);
    float ridge = abs(a + b * 0.7);
    float width = max(fwidth(ridge), 0.035);
    return 1.0 - smoothstep(0.07, 0.19 + width, ridge);
}

vec3 waterTransmission(float distanceToEye) {
    // Warm colors disappear first; nearby blocks remain readable.
    return exp(-max(distanceToEye, 0.0) * UNDERWATER_DENSITY * vec3(1.55, 0.62, 0.38));
}
#endif