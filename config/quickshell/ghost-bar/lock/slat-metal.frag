void MAIN() {
    float brushed = sin(UV0.y * 920.0 + sin(UV0.x * 23.0 + bladeSeed) * 0.7);
    float grain = fract(sin(dot(UV0, vec2(4719.3, 7921.7)) + bladeSeed) * 43758.5453);
    float variation = brushed * 0.003 + (grain - 0.5) * 0.002;
    BASE_COLOR = vec4(vec3(0.34 + variation), 1.0);
    METALNESS = 0.42;
    ROUGHNESS = 0.34 + grain * 0.015;
}
