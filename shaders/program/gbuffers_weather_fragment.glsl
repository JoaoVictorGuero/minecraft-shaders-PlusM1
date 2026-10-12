uniform sampler2D gtexture;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
in vec2 texcoord;
in vec2 lmcoord;
in vec4 glColor;
in vec4 viewPos;
#include "/lib/common.glsl"

/* DRAWBUFFERS:0 */
void main() {
    vec4 texel = texture(gtexture, texcoord);
    float distanceToEye = length(viewPos.xyz);
    // Keep the original precipitation texture and engine occlusion.
    float fade = smoothstep(0.5, 2.0, distanceToEye);
    fade *= 1.0 - smoothstep(14.0, 32.0, distanceToEye);
    float alpha = pow(texel.a, 1.2) * glColor.a * RAIN_OPACITY * fade;
    if (alpha < 0.005) discard;

    vec2 lm = remapLightmap(lmcoord);
    vec3 sunDir = worldSunDirection(mat3(gbufferModelViewInverse), sunPosition);
    vec3 ambient = getAmbientColor(sunDir.y, 1.0) * (0.35 + 0.65 * lm.y);
    vec3 torch = TORCH_COLOR * lm.x * lm.x * TORCH_STRENGTH;
    vec3 tint = mix(texel.rgb, vec3(luma(texel.rgb)) * vec3(0.83, 0.94, 1.06), 0.65);
    vec3 light = ambient + torch + vec3(MIN_CAVE_LIGHT);
    gl_FragData[0] = vec4(tint * glColor.rgb * light * 1.4, alpha);
}