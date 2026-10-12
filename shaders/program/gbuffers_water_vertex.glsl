out vec2 texcoord;
out vec2 lmcoord;
out vec4 glColor;
out vec3 normal;
out vec4 viewPos;

flat out int blockId;
in vec4 mc_Entity;

void main() {
    vec4 position = gl_Vertex;
    blockId = int(mc_Entity.x + 0.5);
    
    // Movimento da água removido a pedido do usuário
    // A água agora ficará estática como no Vanilla

    gl_Position = gl_ModelViewProjectionMatrix * position;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glColor = gl_Color;
    normal = normalize(gl_NormalMatrix * gl_Normal);
    viewPos = gl_ModelViewMatrix * position;
}
