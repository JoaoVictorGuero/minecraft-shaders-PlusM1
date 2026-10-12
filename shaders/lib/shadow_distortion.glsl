#ifndef VP_SHADOW_DISTORTION
#define VP_SHADOW_DISTORTION
float getDistortFactor(vec2 p) { return length(p) * 0.9 + 0.1; }
vec3 distortShadow(vec3 p) {
    p.xy /= getDistortFactor(p.xy);
    return p;
}
#endif
