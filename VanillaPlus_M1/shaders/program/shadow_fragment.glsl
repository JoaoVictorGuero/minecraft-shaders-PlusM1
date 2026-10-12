uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 glColor;

void main() {
    vec4 color = texture2D(gtexture, texcoord);
    color *= glColor;

    // Remove coisas transparentes do mapa de sombras (ex: vidro, folhas)
    if (color.a < 0.1) discard;

    gl_FragData[0] = color;
}
