#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float widthPx;
    float heightPx;
    float edgeSide;
    float borderWidth;
    float highlightWidth;
    vec4 bodyRect;
    vec2 flareRadius;
    vec2 farRadius;
    vec4 fillColor;
    vec4 borderColor;
    vec4 highlightColor;
    vec4 shadowColor;
    vec4 shadowParam;
    vec4 ambientParam;
} ubuf;

vec2 canonicalPoint(vec2 px) {
    vec2 p = px - ubuf.bodyRect.xy;
    if (ubuf.edgeSide < 0.5)
        return p;
    if (ubuf.edgeSide < 1.5)
        return vec2(p.x, ubuf.bodyRect.w - p.y);
    if (ubuf.edgeSide < 2.5)
        return p.yx;
    return vec2(p.y, ubuf.bodyRect.z - p.x);
}

float sideDist(vec2 p, float depth, float farRadius) {
    vec2 r = ubuf.flareRadius;
    if (r.x > 0.0 && r.y > 0.0 && p.y < r.y) {
        vec2 q = max(vec2(p.x + r.x, r.y - p.y), vec2(0.0));
        vec2 n = q / r;
        vec2 g = q / (r * r);
        // A finite denominator keeps the concave field continuous into the straight side.
        float e = (dot(n, n) - 1.0) / (length(g) + length(vec2(1.0 / r.x, g.y)));
        return -e + max(-p.x - r.x, 0.0);
    }
    if (farRadius > 0.0 && p.y > depth - farRadius && p.x < farRadius)
        return length(p - vec2(farRadius, depth - farRadius)) - farRadius;
    return -p.x;
}

float sceneDist(vec2 px) {
    vec2 p = canonicalPoint(px);
    vec2 size = ubuf.edgeSide < 1.5 ? ubuf.bodyRect.zw : ubuf.bodyRect.wz;
    // Only exterior boundaries participate; the flare/body joins have no edge.
    float left = sideDist(p, size.y, ubuf.farRadius.x);
    float right = sideDist(vec2(size.x - p.x, p.y), size.y, ubuf.farRadius.y);
    return max(max(left, right), max(-p.y, p.y - size.y));
}

void main() {
    vec2 px = qt_TexCoord0 * vec2(ubuf.widthPx, ubuf.heightPx);
    float d = sceneDist(px);
    // Steep far-field derivatives must not create coverage away from the outline.
    float fw = max(min(fwidth(d), length(fwidth(px))), 0.0001);
    float aa = fw * 0.5;
    float cov = 1.0 - smoothstep(-aa, aa, d);
    float alpha = ubuf.fillColor.a;
    vec4 col = vec4(ubuf.fillColor.rgb * alpha, alpha);

    float borderAlpha = ubuf.borderWidth > 0.0 ? smoothstep(-ubuf.borderWidth - aa, -ubuf.borderWidth + aa, d) * ubuf.borderColor.a : 0.0;
    col = vec4(ubuf.borderColor.rgb * borderAlpha, borderAlpha) + col * (1.0 - borderAlpha);
    float light = mix(1.0, 0.2, clamp((px.y - ubuf.bodyRect.y) / max(ubuf.bodyRect.w, 1.0), 0.0, 1.0));
    float highlightAlpha = ubuf.highlightWidth > 0.0 ? smoothstep(-ubuf.highlightWidth - aa, -ubuf.highlightWidth + aa, d) * light * ubuf.highlightColor.a : 0.0;
    col = vec4(ubuf.highlightColor.rgb * highlightAlpha, highlightAlpha) + col * (1.0 - highlightAlpha);
    col *= cov;

    if (ubuf.shadowColor.a > 0.0) {
        float dk = sceneDist(px - ubuf.shadowParam.zw) - ubuf.shadowParam.y;
        float bk = max(ubuf.shadowParam.x, fw);
        float covK = 1.0 - smoothstep(-bk, bk, dk);
        float ba = max(ubuf.ambientParam.x, fw);
        float covA = 1.0 - smoothstep(-ba, ba, d - ubuf.ambientParam.y);
        float sh = (1.0 - (1.0 - covK * ubuf.shadowColor.a) * (1.0 - covA * ubuf.ambientParam.z)) * (1.0 - cov);
        col += vec4(ubuf.shadowColor.rgb * sh, sh);
    }

    fragColor = col * ubuf.qt_Opacity;
}
