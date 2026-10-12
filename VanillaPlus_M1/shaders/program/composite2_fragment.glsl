uniform sampler2D colortex0;
uniform sampler2D colortex1;
in vec2 texcoord;
#include "/lib/settings.glsl"
const bool colortex1MipmapEnabled = true;
vec3 toneMap(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}
vec3 getBloom(vec2 uv) {
    vec2 edge = 0.5 / vec2(textureSize(colortex1, 4));
    uv = clamp(uv, edge, 1.0 - edge);
    return (textureLod(colortex1, uv, 2.0).rgb
          + textureLod(colortex1, uv, 3.0).rgb * 0.9
          + textureLod(colortex1, uv, 4.0).rgb * 0.8
          + textureLod(colortex1, uv, 5.0).rgb * 0.7
          + textureLod(colortex1, uv, 6.0).rgb * 0.6) * 0.25;
}
/* DRAWBUFFERS:0 */
void main() {
    vec3 color = max(texture(colortex0, texcoord).rgb, vec3(0.0));
    if (BLOOM_STRENGTH > 0.0) color += getBloom(texcoord) * BLOOM_STRENGTH;
    color = toneMap(color * EXPOSURE);
    float l = dot(color, vec3(0.2126, 0.7152, 0.0722));
    vec3 chroma = color - vec3(l);
    float peak = max(color.r, max(color.g, color.b));
    float floorColor = min(color.r, min(color.g, color.b));
    float colorfulness = (peak - floorColor) / max(peak, 0.001);
    // Lift muted colors most; protect bright clouds and already vivid materials.
    float highlightProtection = 1.0 - smoothstep(0.65, 0.95, l);
    float strength = SATURATION + VIBRANCE * (1.0 - colorfulness) * highlightProtection;
    // Keep luminance and hue without clipping individual RGB channels.
    float positiveChroma = max(chroma.r, max(chroma.g, chroma.b));
    float negativeChroma = -min(chroma.r, min(chroma.g, chroma.b));
    float gamutLimit = min((1.0 - l) / max(positiveChroma, 0.00001),
                          l / max(negativeChroma, 0.00001));
    color = vec3(l) + chroma * min(strength, max(gamutLimit, 0.0));
    vec2 v = texcoord - 0.5;
    color *= 1.0 - dot(v, v) * VIGNETTE * 1.6;
    gl_FragData[0] = vec4(clamp(color, 0.0, 1.0), 1.0);
}
