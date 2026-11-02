pragma ComponentBehavior: Bound

import QtQuick
import qs.Common

Item {
    id: root

    property string edge: "top"
    property real alongRadius: 0
    property real crossRadius: 0
    property point farRadii: Qt.point(0, 0)
    property color fillColor: "transparent"
    property color borderColor: "transparent"
    property real borderWidth: 0
    property real highlight: 0
    property bool shadowEnabled: false
    property string shadowDirection: Theme.elevationLightDirection
    property bool reducedMotion: false

    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property var level: Theme.elevationLevel2
    readonly property var ambient: Theme.elevationAmbient(level)
    readonly property color shadowColor: Theme.elevationShadowColor(level)
    readonly property real offsetX: Theme.elevationOffsetXFor(level, shadowDirection, Theme.spacingXS)
    readonly property real offsetY: Theme.elevationOffsetYFor(level, shadowDirection, Theme.spacingXS)
    readonly property real padding: shadowEnabled ? Math.ceil(Math.max(level.blurPx + level.spreadPx + Math.max(Math.abs(offsetX), Math.abs(offsetY)), ambient.blurPx + ambient.spreadPx) + Theme.outlineWidthFocused) : Theme.outlineWidth

    Behavior on fillColor {
        ColorAnimation {
            duration: root.reducedMotion ? 0 : Theme.shortDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on borderColor {
        ColorAnimation {
            duration: root.reducedMotion ? 0 : Theme.shortDuration
            easing.type: Easing.OutCubic
        }
    }

    ShaderEffect {
        x: -root.padding - (root.vertical ? 0 : root.alongRadius)
        y: -root.padding - (root.vertical ? root.alongRadius : 0)
        width: root.width + root.padding * 2 + (root.vertical ? 0 : root.alongRadius * 2)
        height: root.height + root.padding * 2 + (root.vertical ? root.alongRadius * 2 : 0)
        visible: root.width > 0 && root.height > 0
        fragmentShader: Qt.resolvedUrl("../../Shaders/qsb/gothic_surface.frag.qsb")

        property real widthPx: width
        property real heightPx: height
        property real edgeSide: root.edge === "bottom" ? 1 : root.edge === "left" ? 2 : root.edge === "right" ? 3 : 0
        property real borderWidth: root.borderWidth
        property real highlightWidth: Theme.outlineWidth
        property vector4d bodyRect: Qt.vector4d(-x, -y, root.width, root.height)
        property vector2d flareRadius: Qt.vector2d(root.alongRadius, root.crossRadius)
        property vector2d farRadius: Qt.vector2d(root.farRadii.x, root.farRadii.y)
        property vector4d fillColor: Qt.vector4d(root.fillColor.r, root.fillColor.g, root.fillColor.b, root.fillColor.a)
        property vector4d borderColor: Qt.vector4d(root.borderColor.r, root.borderColor.g, root.borderColor.b, root.borderColor.a)
        property vector4d highlightColor: Qt.vector4d(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, Math.max(0, Math.min(0.4, root.highlight)))
        property vector4d shadowColor: Qt.vector4d(root.shadowColor.r, root.shadowColor.g, root.shadowColor.b, root.shadowEnabled ? root.shadowColor.a : 0)
        property vector4d shadowParam: Qt.vector4d(root.level.blurPx, root.level.spreadPx, root.offsetX, root.offsetY)
        property vector4d ambientParam: Qt.vector4d(root.ambient.blurPx, root.ambient.spreadPx, root.shadowEnabled ? root.ambient.alpha : 0, 0)
    }
}
