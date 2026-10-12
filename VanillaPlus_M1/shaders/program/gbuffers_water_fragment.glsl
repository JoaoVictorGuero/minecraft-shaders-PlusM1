uniform sampler2D gtexture;
uniform sampler2D depthtex1;
uniform vec3 sunPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform float viewWidth;
uniform float viewHeight;
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
#include "/lib/aurora.glsl"
#include "/lib/portals.glsl"
/* DRAWBUFFERS:0 */
void main() {
    vec4 color = texture(gtexture, texcoord) * glColor;
    if (isPortalMaterial(blockId)) {
        vec3 worldPos = (gbufferModelViewInverse * viewPos).xyz + cameraPosition;
        renderPortal(color, worldPos, blockId);
        return;
    }
    if (color.a < 0.01) discard;
    vec3 sunDir = worldSunDirection(mat3(gbufferModelViewInverse), sunPosition);
    vec3 n = normalize(mat3(gbufferModelViewInverse) * normal);
    vec2 lm = remapLightmap(lmcoord);
    vec4 hand = getHandLight(viewPos.xyz, n, mat3(gbufferModelViewInverse));
    vec3 lighting = getSceneLighting(n, sunDir, lmcoord, 1.0, 0.0, rainStrength, hand);
    // Material ID is essential: glass, ice and slime share this program.
    if (blockId == 10004) {
        vec3 incident = normalize(mat3(gbufferModelViewInverse) * viewPos.xyz);
        if (dot(n, -incident) < 0.0) n = -n;
        float facing = clamp(dot(n, -incident), 0.0, 1.0);
        float fresnel = 0.02 + 0.98 * pow(1.0 - facing, 5.0);
        vec2 screenUV = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
        float depth = texture(depthtex1, screenUV).r;
        vec4 behind = gbufferProjectionInverse * vec4(screenUV * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
        float thickness = depth >= 0.999999 ? 32.0 : clamp(length(behind.xyz / behind.w) - length(viewPos.xyz), 0.0, 32.0);
        float absorption = 1.0 - exp(-thickness * WATER_DENSITY);
        vec3 tint = mix(vec3(0.09, 0.32, 0.38), glColor.rgb * vec3(0.3, 0.55, 0.62), 0.5);
        vec3 body = mix(color.rgb, tint, absorption * 0.7) * lighting;
        vec3 reflected = reflect(incident, n);
        vec3 sky = getSkyColor(reflected, sunDir, rainStrength);
        sky += getAurora(reflected);
        float skyVisibility = vpIsOverworld() ? smoothstep(0.45, 0.95, lm.y) : (vpIsNether() ? 0.0 : 1.0);
        float reflection = fresnel * WATER_REFLECTION * skyVisibility;
        if (isEyeInWater == 1) reflection = 0.0;
        color.rgb = mix(body, sky, reflection);
        color.a = clamp(0.18 + absorption * 0.58 + reflection * 0.24, 0.18, 0.94);
    } else {
        color.rgb *= lighting;
    }
    gl_FragData[0] = color;
}
