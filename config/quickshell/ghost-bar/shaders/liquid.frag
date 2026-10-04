#version 440

// The static Canvas texture supplies the exact original rounded-diamond alpha,
// hover color and focus stroke. Only the two liquid layers animate on the GPU.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(binding = 1) uniform sampler2D source;
layout(std140, binding = 0) uniform Uniforms {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 meterSize;
    float wavePhase;
    float waterLine;
    float waveAmplitude;
    float fillEnabled;
};

float waveHeight(float x, float phase) {
    // Interpolate the same 2px vertices as the Canvas fallback, not a new curve.
    float left = floor(x / 2.0) * 2.0;
    float t = (x - left) / 2.0;
    float a = sin(left / meterSize.x * 6.28 + phase);
    float b = sin((left + 2.0) / meterSize.x * 6.28 + phase);
    return waterLine + mix(a, b, t) * waveAmplitude;
}

void main() {
    vec4 base = texture(source, qt_TexCoord0);
    vec2 pixel = qt_TexCoord0 * meterSize;
    vec3 material = base.a > 0.0 ? base.rgb / base.a : vec3(0.0);
    if (fillEnabled > 0.5) {
        float back = pixel.y - waveHeight(pixel.x, wavePhase);
        float front = pixel.y - waveHeight(pixel.x, wavePhase + 1.5);
        float backAA = max(fwidth(back), 0.001);
        float frontAA = max(fwidth(front), 0.001);
        material = mix(material, vec3(184.0 / 255.0), smoothstep(-backAA * 0.5, backAA * 0.5, back));
        material = mix(material, vec3(241.0 / 255.0), smoothstep(-frontAA * 0.5, frontAA * 0.5, front));
    }
    // Qt Quick expects premultiplied output, including inherited opacity.
    fragColor = vec4(material * base.a, base.a) * qt_Opacity;
}
