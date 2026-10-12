uniform sampler2D gtexture;
uniform sampler2D shadowtex1;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform float rainStrength;
uniform vec4 entityColor; // Flash vermelho de dano

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glColor;
in vec3 normal;
in vec4 viewPos;

#include "/lib/common.glsl"
#include "/lib/shadows.glsl"

/* DRAWBUFFERS:0 */
void main() {
    vec4 color = texture(gtexture, texcoord);
    if (color.a < 0.1) discard;

    color *= glColor;
    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a); // Mantém o flash de dano

    vec3 worldNormal = normalize(mat3(gbufferModelViewInverse) * normal);
    vec3 sunDir = worldSunDirection(mat3(gbufferModelViewInverse), sunPosition);

    float shadow = getSoftShadow(viewPos, worldNormal, sunDir, 0.0);
    vec4 hand = getHandLight(viewPos.xyz, worldNormal, mat3(gbufferModelViewInverse));
    vec3 albedo = color.rgb;
    color.rgb *= getSceneLighting(worldNormal, sunDir, lmcoord, shadow, 0.0, rainStrength, hand);

    // Olhos do Ender Dragon e Endermen brilham no escuro e alimentam o bloom
    float entityMax = max(albedo.r, max(albedo.g, albedo.b));
    float entityMin = min(albedo.r, min(albedo.g, albedo.b));
    float entitySat = (entityMax - entityMin) / max(entityMax, 0.001);
    float purpleEye = smoothstep(0.18, 0.48, (min(albedo.r, albedo.b) - albedo.g * 0.75) / max(max(albedo.r, albedo.b), 0.001))
                    * smoothstep(0.25, 0.60, entitySat);
    if (purpleEye > 0.01) {
        vec3 eyeGlow = albedo * EMISSIVE_BOOST * 1.25;
        color.rgb = mix(color.rgb, eyeGlow, purpleEye);
    }

    gl_FragData[0] = color;
}
