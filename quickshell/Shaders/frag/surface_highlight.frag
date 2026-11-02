#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float widthPx;
    float heightPx;
    float lineWidth;
    vec4 cornerRadii;
    vec4 highlightColor;
} ubuf;

void main() {
    vec2 size = vec2(ubuf.widthPx, ubuf.heightPx);
    vec2 p = (qt_TexCoord0 - 0.5) * size;
    float radius = p.x < 0.0
        ? (p.y < 0.0 ? ubuf.cornerRadii.x : ubuf.cornerRadii.z)
        : (p.y < 0.0 ? ubuf.cornerRadii.y : ubuf.cornerRadii.w);
    radius = clamp(radius, 0.0, min(size.x, size.y) * 0.5);
    vec2 q = abs(p) - size * 0.5 + radius;
    float distance = min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - radius;
    float aa = max(fwidth(distance), 0.001);
    float outer = 1.0 - smoothstep(-aa, aa, distance);
    float inner = 1.0 - smoothstep(-aa, aa, distance + ubuf.lineWidth);
    float light = mix(1.0, 0.2, qt_TexCoord0.y);
    float alpha = max(0.0, outer - inner) * light * ubuf.highlightColor.a * ubuf.qt_Opacity;
    fragColor = vec4(ubuf.highlightColor.rgb * alpha, alpha);
}
