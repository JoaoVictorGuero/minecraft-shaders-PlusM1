/* DRAWBUFFERS:0 */
void main() {
    // Nós destruímos o céu Vanilla (SkyBasic) jogando a opacidade (alpha) para ZERO!
    // Assim, no composite.fsh nós conseguimos desenhar o NOSSO céu cinematográfico
    // sem que o Minecraft coloque o céu dele por cima estragando as cores!
    gl_FragData[0] = vec4(0.0, 0.0, 0.0, 0.0);
}
