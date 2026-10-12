out vec2 texcoord;
out vec4 glColor;
out vec3 normal;
out vec4 viewPos;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glColor = gl_Color;

    // Normal para a nuvem receber luz
    normal = normalize(gl_NormalMatrix * gl_Normal);
    viewPos = gl_ModelViewMatrix * gl_Vertex;
}
