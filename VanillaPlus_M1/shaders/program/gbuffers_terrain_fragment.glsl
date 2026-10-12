uniform sampler2D gtexture;
uniform sampler2D shadowtex1;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform float rainStrength;
uniform int isEyeInWater;
uniform vec3 cameraPosition;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glColor;
in vec3 normal;
in vec4 viewPos;
flat in int blockId;

#include "/lib/common.glsl"
#include "/lib/shadows.glsl"
#include "/lib/water_optics.glsl"
#include "/lib/portals.glsl"

/* DRAWBUFFERS:0 */
void main() {
    vec4 color = texture(gtexture, texcoord);
    if (isPortalMaterial(blockId)) {
        vec3 worldPos = (gbufferModelViewInverse * viewPos).xyz + cameraPosition;
        renderPortal(color * glColor, worldPos, blockId);
        return;
    }
    if (color.a < 0.1) discard;

    color *= glColor; // Cor do bioma + AO vanilla

    vec3 worldNormal = normalize(mat3(gbufferModelViewInverse) * normal);
    vec3 sunDir = worldSunDirection(mat3(gbufferModelViewInverse), sunPosition);

    float foliage = (blockId >= 10000 && blockId <= 10003) ? 1.0 : 0.0;
    float emissive = (blockId >= 10010 && blockId <= 10016) ? 1.0 : 0.0;

    float shadow = getSoftShadow(viewPos, worldNormal, sunDir, foliage);
    vec4 hand = getHandLight(viewPos.xyz, worldNormal, mat3(gbufferModelViewInverse));
    vec3 lighting = getSceneLighting(worldNormal, sunDir, lmcoord, shadow, foliage, rainStrength, hand);

    // Blocos que emitem luz brilham de verdade (alimenta o bloom)
    vec3 albedo = color.rgb;
    vec3 lit = albedo * lighting;
    if (isEyeInWater == 1 && vpIsOverworld() && WATER_CAUSTICS > 0.0) {
        vec3 relativePos = (gbufferModelViewInverse * viewPos).xyz;
        vec3 worldPos = relativePos + cameraPosition;
        vec2 lm = remapLightmap(lmcoord);
        float submerged = 1.0 - smoothstep(-0.4, 0.0, relativePos.y);
        float visibility = lm.y * lm.y * max(worldNormal.y, 0.0) * shadow;
        visibility *= dayMix(sunDir.y) * (1.0 - rainStrength * 0.8) * submerged;
        lit += albedo * vec3(0.48, 0.85, 0.92) * waterCaustics(worldPos)
             * visibility * WATER_CAUSTICS * (1.0 - emissive);
    }
    vec3 glow = albedo * EMISSIVE_BOOST * (0.4 + 0.6 * luma(albedo));
    float emissionDetail = smoothstep(0.45, 0.85, max(albedo.r, max(albedo.g, albedo.b)));
    color.rgb = mix(lit, max(lit, glow), emissive * emissionDetail);

    gl_FragData[0] = color;
}
