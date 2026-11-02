import QtQuick
import qs.Common

ShaderEffect {
    id: root

    property real strength: 0
    property real radius: Theme.windowRadius
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomLeftRadius: radius
    property real bottomRightRadius: radius
    property real lineWidth: Theme.outlineWidth
    property color lightColor: Theme.surfaceText
    readonly property real widthPx: width
    readonly property real heightPx: height
    readonly property vector4d cornerRadii: Qt.vector4d(topLeftRadius, topRightRadius, bottomLeftRadius, bottomRightRadius)
    readonly property vector4d highlightColor: Qt.vector4d(lightColor.r, lightColor.g, lightColor.b, Math.max(0, Math.min(0.4, strength)))

    visible: strength > 0 && width > 0 && height > 0
    blending: true
    fragmentShader: Qt.resolvedUrl("../Shaders/qsb/surface_highlight.frag.qsb")
}
