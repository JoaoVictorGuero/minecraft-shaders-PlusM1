uniform sampler2D gtexture;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glColor;
in vec4 viewPos;

#include "/lib/common.glsl"

/* DRAWBUFFERS:0 */
void main() {
    vec4 color = texture(gtexture, texcoord) * glColor;
    if (color.a < 0.01) discard;

    vec3 albedo = color.rgb;

    // Métricas de cor para detecção de partículas mágicas e do The End
    float maxC = max(albedo.r, max(albedo.g, albedo.b));
    float minC = min(albedo.r, min(albedo.g, albedo.b));
    float sat = (maxC - minC) / max(maxC, 0.001);

    // 1. Partículas do Ender Dragon, Portal, Enderman e magia arroxeada/magenta
    // Dominância roxa: R e B altos, G baixo + saturação pronunciada
    float purpleDominance = (min(albedo.r, albedo.b) - albedo.g * 0.75) / max(max(albedo.r, albedo.b), 0.001);
    float isEnderParticle = smoothstep(0.18, 0.50, purpleDominance) * smoothstep(0.20, 0.55, sat);

    // 2. Partículas do End Rod (faíscas brancas/celestiais muito brilhantes no The End)
    float isEndRod = smoothstep(0.82, 0.96, minC) * (1.0 - smoothstep(0.0, 0.15, sat));

    // 3. Partículas de fogo e lava (chamas âmbar/laranja)
    float isFlame = smoothstep(0.35, 0.75, (albedo.r - albedo.b) / max(albedo.r, 0.001)) * smoothstep(0.3, 0.7, albedo.g) * smoothstep(0.35, 0.7, sat);

    // 4. Partículas de fogo de alma / soul flame (ciano/azul)
    float isSoul = smoothstep(0.30, 0.70, (albedo.b - albedo.r) / max(albedo.b, 0.001)) * smoothstep(0.3, 0.7, albedo.g) * smoothstep(0.35, 0.7, sat);

    // Cálculo do multiplicador de brilho/glow
    float glowFactor = 0.0;
    if (isEnderParticle > 0.001) {
        // No The End ou em dragão/portal: brilho HDR intenso para alimentar o Bloom
        float boost = vpIsEnd() ? 3.8 : 3.0;
        glowFactor = isEnderParticle * boost;
    } else if (isEndRod > 0.001) {
        glowFactor = isEndRod * (vpIsEnd() ? 2.8 : 2.2);
    } else if (isFlame > 0.001) {
        glowFactor = isFlame * 2.2;
    } else if (isSoul > 0.001) {
        glowFactor = isSoul * 2.6;
    }

    if (glowFactor > 0.001) {
        // Partícula emissiva: projeta brilho HDR e saturação mágica para o Bloom
        color.rgb = albedo * (1.0 + glowFactor);
    } else {
        // Partículas normais (fumaça cinza, respingos d'água, terra): recebem luz do lightmap
        vec2 lm = remapLightmap(lmcoord);
        float light = mix(MIN_CAVE_LIGHT * 2.0, 1.0, max(lm.x, lm.y * 0.85));
        color.rgb *= (0.45 + 0.55 * light);
    }

    gl_FragData[0] = color;
}
