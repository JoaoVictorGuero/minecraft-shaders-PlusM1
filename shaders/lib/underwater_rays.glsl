#ifndef VP_UNDERWATER_RAYS
#define VP_UNDERWATER_RAYS

#include "/lib/volume_shadows.glsl"

vec3 traceUnderwaterRays(vec3 direction, vec3 sunDir, float sceneDistance, float eyeSky) {
    float daylight = smoothstep(0.02, 0.25, sunDir.y);
    float skyAccess = smoothstep(0.0, 0.65, eyeSky);
    float strength = UNDERWATER_RAYS * daylight * skyAccess * (1.0 - rainStrength * 0.85);
    if (!vpIsOverworld() || strength <= 0.001) return vec3(0.0);

    // Snell's law bends incoming sunlight toward the vertical inside water.
    vec3 lightDir = -refract(-sunDir, vec3(0.0, 1.0, 0.0), 0.75);
    vec3 axis = lightDir.y > 0.95 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
    vec3 beamX = normalize(cross(lightDir, axis));
    vec3 beamY = cross(lightDir, beamX);
    vec3 origin = gbufferModelViewInverse[3].xyz;
    vec3 worldOrigin = cameraPosition + origin;
    vec2 patternOrigin = vec2(dot(worldOrigin, beamX), dot(worldOrigin, beamY)) * 0.8;
    vec2 patternDirection = vec2(dot(direction, beamX), dot(direction, beamY)) * 0.8;

    float range = min(max(sceneDistance, 0.0), min(32.0, shadowDistance * 0.6));
    float stepLength = range / float(UNDERWATER_RAY_STEPS);
    // Fixed subpixel jitter breaks up marching bands without temporal flicker.
    float jitter = fract(52.9829189 * fract(dot(gl_FragCoord.xy, vec2(0.06711056, 0.00583715))));
    vec3 extinction = UNDERWATER_DENSITY * vec3(1.55, 0.62, 0.38);
    vec3 transmissionStep = exp(-extinction * stepLength);
    vec3 transmission = exp(-extinction * stepLength * (0.25 + 0.5 * jitter));
    vec3 scattered = vec3(0.0);
    float t = frameTimeCounter * 0.3;

    for (int i = 0; i < UNDERWATER_RAY_STEPS; ++i) {
        float distanceToEye = (float(i) + 0.25 + 0.5 * jitter) * stepLength;
        vec3 samplePos = origin + direction * distanceToEye;
        float visibility = volumeSunVisibility(samplePos);
        if (visibility > 0.0) {
            // The pattern is constant along each refracted sun ray: long shafts,
            // rather than blobs floating in front of the camera.
            vec2 p = patternOrigin + patternDirection * distanceToEye;
            float focus = sin(p.x + sin(p.y * 0.62 + t) * 0.8)
                        + sin(p.y * 1.13 - t * 0.7);
            float beam = smoothstep(0.45, 1.65, focus);
            float sunDepth = max(-direction.y * distanceToEye, 0.0) / max(lightDir.y, 0.2);
            float sunTransmission = exp(-UNDERWATER_DENSITY * sunDepth * 0.75);
            scattered += transmission * visibility * (0.08 + beam * 0.92) * sunTransmission;
        }
        transmission *= transmissionStep;
    }

    float alignment = clamp(dot(direction, lightDir), -1.0, 1.0);
    float phase = 0.6975 / pow(max(1.3025 - 1.1 * alignment, 0.2025), 1.5);
    phase = 0.55 + 0.35 * min(phase, 4.0);
    vec3 sunlight = getLightColor(sunDir.y, 0.0) * vec3(0.42, 0.8, 0.92);
    return scattered * sunlight * (UNDERWATER_DENSITY * stepLength * 0.75 * phase * strength);
}
#endif