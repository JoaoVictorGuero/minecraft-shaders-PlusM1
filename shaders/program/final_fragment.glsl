uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;
in vec2 texcoord;

#include "/lib/settings.glsl"

float getLuma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 sampleColor(vec2 uv, vec2 pixel) {
    return texture(colortex0, clamp(uv, pixel * 0.5, 1.0 - pixel * 0.5)).rgb;
}

#if FXAA == 1
// =========================================================================
//  Nivel 1: FXAA Rapido (Leve e eficiente)
// =========================================================================
vec3 fxaaFast(vec2 uv, vec2 pixel, vec3 center) {
    float nw = getLuma(sampleColor(uv + pixel * vec2(-1.0, -1.0), pixel));
    float ne = getLuma(sampleColor(uv + pixel * vec2( 1.0, -1.0), pixel));
    float sw = getLuma(sampleColor(uv + pixel * vec2(-1.0,  1.0), pixel));
    float se = getLuma(sampleColor(uv + pixel * vec2( 1.0,  1.0), pixel));
    float m  = getLuma(center);

    float lo = min(m, min(min(nw, ne), min(sw, se)));
    float hi = max(m, max(max(nw, ne), max(sw, se)));
    if (hi - lo < max(0.04, hi * 0.125)) return center;

    vec2 dir = vec2(-(nw + ne - sw - se), nw + sw - ne - se);
    float reduce = max((nw + ne + sw + se) * 0.03125, 0.0078125);
    dir = clamp(dir / (min(abs(dir.x), abs(dir.y)) + reduce), vec2(-6.0), vec2(6.0)) * pixel;

    vec3 a = 0.5 * (sampleColor(uv - dir / 6.0, pixel) + sampleColor(uv + dir / 6.0, pixel));
    vec3 b = a * 0.5 + 0.25 * (sampleColor(uv - dir * 0.5, pixel) + sampleColor(uv + dir * 0.5, pixel));
    float lb = getLuma(b);
    return (lb < lo || lb > hi) ? a : b;
}
#endif

#if FXAA >= 2
// =========================================================================
//  Nivel 2 (Ultra FXAA 3.11) e Nivel 3 (Extremo / Cinematografico)
// =========================================================================
vec3 fxaaQuality(vec2 uv, vec2 pixel, vec3 rgbM, bool extremeMode) {
    float lumaM = getLuma(rgbM);

    vec3 rgbN = sampleColor(uv + vec2( 0.0, -pixel.y), pixel);
    vec3 rgbS = sampleColor(uv + vec2( 0.0,  pixel.y), pixel);
    vec3 rgbW = sampleColor(uv + vec2(-pixel.x,  0.0), pixel);
    vec3 rgbE = sampleColor(uv + vec2( pixel.x,  0.0), pixel);

    float lumaN = getLuma(rgbN);
    float lumaS = getLuma(rgbS);
    float lumaW = getLuma(rgbW);
    float lumaE = getLuma(rgbE);

    float lumaMin = min(lumaM, min(min(lumaN, lumaW), min(lumaS, lumaE)));
    float lumaMax = max(lumaM, max(max(lumaN, lumaW), max(lumaS, lumaE)));

    float lumaNW = getLuma(sampleColor(uv + pixel * vec2(-1.0, -1.0), pixel));
    float lumaNE = getLuma(sampleColor(uv + pixel * vec2( 1.0, -1.0), pixel));
    float lumaSW = getLuma(sampleColor(uv + pixel * vec2(-1.0,  1.0), pixel));
    float lumaSE = getLuma(sampleColor(uv + pixel * vec2( 1.0,  1.0), pixel));

    lumaMin = min(lumaMin, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    lumaMax = max(lumaMax, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    float lumaRange = lumaMax - lumaMin;

    float edgeThreshold = extremeMode ? 0.0625 : 0.0833;
    float edgeMin = extremeMode ? 0.025 : 0.0312;
    if (lumaRange < max(edgeMin, lumaMax * edgeThreshold)) {
        return rgbM;
    }

    // Filtragem subpixel
    float lumaL = (2.0 * (lumaN + lumaS + lumaE + lumaW) + (lumaNW + lumaNE + lumaSW + lumaSE)) * (1.0 / 12.0);
    float subpix = clamp(abs(lumaL - lumaM) / lumaRange, 0.0, 1.0);
    float subpixOffset = smoothstep(0.0, 1.0, subpix) * subpix * (extremeMode ? 0.90 : 0.75);

    // Orientacao da aresta (Horizontal vs Vertical)
    float edgeH = abs(lumaNW - 2.0 * lumaN + lumaNE) * 2.0
                + abs(lumaW  - 2.0 * lumaM + lumaE ) * 4.0
                + abs(lumaSW - 2.0 * lumaS + lumaSE) * 2.0;

    float edgeV = abs(lumaNW - 2.0 * lumaW + lumaSW) * 2.0
                + abs(lumaN  - 2.0 * lumaM + lumaS ) * 4.0
                + abs(lumaNE - 2.0 * lumaE + lumaSE) * 2.0;

    bool isHoriz = (edgeH >= edgeV);

    float lumaNeg = isHoriz ? lumaN : lumaW;
    float lumaPos = isHoriz ? lumaS : lumaE;
    float gradNeg = abs(lumaNeg - lumaM);
    float gradPos = abs(lumaPos - lumaM);

    float stepLength = isHoriz ? pixel.y : pixel.x;
    float lumaOpposite;
    float gradient;

    if (gradNeg >= gradPos) {
        stepLength = -stepLength;
        lumaOpposite = lumaNeg;
        gradient = gradNeg;
    } else {
        lumaOpposite = lumaPos;
        gradient = gradPos;
    }

    vec2 uvEdge = uv;
    if (isHoriz) uvEdge.y += stepLength * 0.5;
    else         uvEdge.x += stepLength * 0.5;

    // Rastreamento das extremidades da aresta
    vec2 edgeStep = isHoriz ? vec2(pixel.x, 0.0) : vec2(0.0, pixel.y);
    float lumaEdgeCenter = (lumaM + lumaOpposite) * 0.5;
    float gradThreshold = gradient * 0.25;

    vec2 uvNeg = uvEdge - edgeStep;
    vec2 uvPos = uvEdge + edgeStep;

    float lumaEndNeg = 0.0;
    float lumaEndPos = 0.0;
    bool doneNeg = false;
    bool donePos = false;

    const int STEPS = 10;
    float stepScale[STEPS] = float[STEPS](1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 2.0, 2.5, 3.0, 4.0);

    for (int i = 0; i < STEPS; ++i) {
        if (!doneNeg) {
            lumaEndNeg = getLuma(sampleColor(uvNeg, pixel)) - lumaEdgeCenter;
            doneNeg = abs(lumaEndNeg) >= gradThreshold;
            if (!doneNeg) uvNeg -= edgeStep * stepScale[i];
        }
        if (!donePos) {
            lumaEndPos = getLuma(sampleColor(uvPos, pixel)) - lumaEdgeCenter;
            donePos = abs(lumaEndPos) >= gradThreshold;
            if (!donePos) uvPos += edgeStep * stepScale[i];
        }
        if (doneNeg && donePos) break;
    }

    float distNeg = isHoriz ? (uv.x - uvNeg.x) : (uv.y - uvNeg.y);
    float distPos = isHoriz ? (uvPos.x - uv.x) : (uvPos.y - uv.y);
    distNeg = max(distNeg, 0.0001);
    distPos = max(distPos, 0.0001);

    bool isNegCloser = (distNeg < distPos);
    float distMin = min(distNeg, distPos);
    float edgeSpan = distNeg + distPos;

    float edgeOffset = 0.5 - (distMin / edgeSpan);
    float lumaEndMin = isNegCloser ? lumaEndNeg : lumaEndPos;
    bool isPairingCorrect = (lumaEndMin < 0.0) == (lumaM - lumaEdgeCenter < 0.0);
    if (!isPairingCorrect) edgeOffset = 0.0;

    float finalOffset = max(edgeOffset, subpixOffset);

    vec2 finalUV = uv;
    if (isHoriz) finalUV.y += finalOffset * stepLength;
    else         finalUV.x += finalOffset * stepLength;

    vec3 blended = sampleColor(finalUV, pixel);

    // Modo Extremo: reconstrucao morfologica diagonal e preservacao de nitidez
    if (extremeMode) {
        vec2 diagStep = pixel * 0.7071;
        float diagContrast = abs(lumaNW + lumaSE - lumaNE - lumaSW);
        if (diagContrast > lumaRange * 0.4) {
            vec3 diagColor = 0.5 * (sampleColor(uv + diagStep, pixel) + sampleColor(uv - diagStep, pixel));
            blended = mix(blended, diagColor, 0.35);
        }

        // Color box clamp: mantem nitidez total nas texturas sem borrar
        vec3 boxMin = min(rgbM, min(min(rgbN, rgbS), min(rgbW, rgbE)));
        vec3 boxMax = max(rgbM, max(max(rgbN, rgbS), max(rgbW, rgbE)));
        blended = clamp(blended, boxMin * 0.95, boxMax * 1.05);
    }

    return blended;
}
#endif

vec3 antialias(vec2 uv) {
    vec2 pixel = 1.0 / vec2(viewWidth, viewHeight);
    vec3 center = sampleColor(uv, pixel);

#if FXAA == 0
    return center;
#elif FXAA == 1
    return fxaaFast(uv, pixel, center);
#elif FXAA == 2
    return fxaaQuality(uv, pixel, center, false);
#elif FXAA >= 3
    return fxaaQuality(uv, pixel, center, true);
#endif
}

void main() {
    vec3 color = antialias(texcoord);
    float noise = fract(52.9829189 * fract(dot(gl_FragCoord.xy, vec2(0.06711056, 0.00583715))));
    color += (noise - 0.5) / 255.0;
    gl_FragData[0] = vec4(clamp(color, 0.0, 1.0), 1.0);
}
