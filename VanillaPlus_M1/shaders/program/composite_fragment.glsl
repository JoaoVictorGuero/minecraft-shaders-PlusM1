uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform float rainStrength;
uniform float far;
uniform int isEyeInWater;
uniform ivec2 eyeBrightnessSmooth;
uniform sampler2D depthtex0;
in vec2 texcoord;
#include "/lib/common.glsl"
#include "/lib/clouds.glsl"
#include "/lib/sun_rays.glsl"
/*
const int colortex5Format = RGBA16F;
const int colortex2Format = RGBA16F;
*/
const vec4 colortex5ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex2ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
/* DRAWBUFFERS:52 */
void main() {
    gl_FragData[0] = vec4(0.0);
    gl_FragData[1] = vec4(0.0);
    if (isEyeInWater != 0 || !vpIsOverworld()) return;
    vec4 view = gbufferProjectionInverse * vec4(texcoord * 2.0 - 1.0, 1.0, 1.0);
    vec3 dir = normalize(mat3(gbufferModelViewInverse) * (view.xyz / view.w));
    vec3 origin = cameraPosition + gbufferModelViewInverse[3].xyz;
    vec3 sunDir = worldSunDirection(mat3(gbufferModelViewInverse), sunPosition);
    #if CLOUD_STYLE != 0
    gl_FragData[0] = traceClouds(origin, dir, sunDir, rainStrength, cloudRange);
    #endif
    if (SUN_RAYS > 0.0) {
        float depth = texture(depthtex0, texcoord).r;
        vec4 surface = gbufferProjectionInverse * vec4(vec3(texcoord, depth) * 2.0 - 1.0, 1.0);
        float distanceToSurface = depth >= 1.0 ? far : length(surface.xyz / surface.w);
        float eyeSky = clamp(float(eyeBrightnessSmooth.y) / 240.0, 0.0, 1.0);
        vec3 rays = depth > 0.56 ? traceSunRays(dir, sunDir, distanceToSurface, eyeSky) : vec3(0.0);
        gl_FragData[1] = vec4(rays, distanceToSurface);
    }
}