pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common

FloatingWindow {
    id: root

    readonly property bool isFloatingWindowSurface: true
    property string materialKind: "settings"

    default property alias content: contentItem.data

    property color surfaceColor: Theme.surfaceColor(materialKind)
    property bool contentVisible: true

    // A placeholder screen (no outputs left) is 0x0; a size derived from it is a zero geometry and the compositor drops the connection.
    function heightWithin(preferred, inset) {
        const available = (root.screen?.height ?? 0) - inset;
        return available > 0 ? Math.min(preferred, available) : preferred;
    }

    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: root.surfaceColor
        visible: root.contentVisible
    }

    SurfaceHighlight {
        anchors.fill: parent
        strength: Theme.surfaceMaterial(root.materialKind).highlight
        visible: root.contentVisible && strength > 0
    }

    WindowBlur {
        targetWindow: root
        materialKind: root.materialKind
        blurEnabled: root.contentVisible
        surfaceColor: root.surfaceColor
        blurX: 0
        blurY: 0
        blurWidth: root.visible ? root.width : 0
        blurHeight: root.visible ? root.height : 0
    }

    Item {
        id: contentItem

        readonly property bool isFloatingWindowSurface: true
        property bool disablePopupTransparency: true

        anchors.fill: parent
        visible: root.contentVisible
    }
}
