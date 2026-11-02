pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Region {
    id: root

    property rect bodyRect: Qt.rect(0, 0, 0, 0)
    property string edge: "top"
    property real alongRadius: 0
    property real crossRadius: 0
    property point farRadii: Qt.point(0, 0)

    readonly property int _bodyX: Math.round(bodyRect.x)
    readonly property int _bodyY: Math.round(bodyRect.y)
    readonly property int _bodyWidth: Math.max(0, Math.round(bodyRect.x + bodyRect.width) - _bodyX)
    readonly property int _bodyHeight: Math.max(0, Math.round(bodyRect.y + bodyRect.height) - _bodyY)
    readonly property bool _horizontal: edge === "top" || edge === "bottom"
    readonly property int _alongExtent: _horizontal ? _bodyWidth : _bodyHeight
    readonly property int _crossExtent: _horizontal ? _bodyHeight : _bodyWidth
    readonly property int _alongRadius: Math.max(0, Math.round(alongRadius))
    readonly property int _crossRadius: Math.max(0, Math.round(crossRadius))
    readonly property int _farLeadingRadius: Math.max(0, Math.round(farRadii.x))
    readonly property int _farTrailingRadius: Math.max(0, Math.round(farRadii.y))
    readonly property bool _hasBody: _bodyWidth > 0 && _bodyHeight > 0
    readonly property bool _hasWings: _hasBody && _alongRadius > 0 && _crossRadius > 0

    function _mapRect(u: real, v: real, along: real, cross: real, shiftX: int, shiftY: int): rect {
        const x = _bodyX + shiftX;
        const y = _bodyY + shiftY;
        switch (edge) {
        case "bottom":
            return Qt.rect(x + u, y + _crossExtent - v - cross, along, cross);
        case "left":
            return Qt.rect(x + v, y + u, cross, along);
        case "right":
            return Qt.rect(x + _crossExtent - v - cross, y + u, cross, along);
        default:
            return Qt.rect(x + u, y + v, along, cross);
        }
    }

    component Silhouette: Region {
        id: silhouette

        property int shiftX: 0
        property int shiftY: 0

        Region {
            // Extend beyond the attached edge so erosion preserves its first visible row.
            readonly property rect bounds: root._mapRect(0, -1, root._alongExtent, root._crossExtent + 1, silhouette.shiftX, silhouette.shiftY)

            x: bounds.x
            y: bounds.y
            width: root._hasBody ? bounds.width : 0
            height: root._hasBody ? bounds.height : 0
            topLeftRadius: root.edge === "bottom" || root.edge === "right" ? root._farLeadingRadius : 0
            topRightRadius: root.edge === "bottom" ? root._farTrailingRadius : root.edge === "left" ? root._farLeadingRadius : 0
            bottomLeftRadius: root.edge === "top" ? root._farLeadingRadius : root.edge === "right" ? root._farTrailingRadius : 0
            bottomRightRadius: root.edge === "top" || root.edge === "left" ? root._farTrailingRadius : 0
        }

        Region {
            readonly property rect bounds: root._mapRect(-root._alongRadius, -1, root._alongRadius, root._crossRadius + 1, silhouette.shiftX, silhouette.shiftY)

            x: bounds.x
            y: bounds.y
            width: root._hasWings ? bounds.width : 0
            height: root._hasWings ? bounds.height : 0

            Region {
                readonly property rect bounds: root._mapRect(-2 * root._alongRadius, 0, 2 * root._alongRadius, 2 * root._crossRadius, silhouette.shiftX, silhouette.shiftY)

                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
                x: bounds.x
                y: bounds.y
                width: bounds.width
                height: bounds.height
            }
        }

        Region {
            readonly property rect bounds: root._mapRect(root._alongExtent, -1, root._alongRadius, root._crossRadius + 1, silhouette.shiftX, silhouette.shiftY)

            x: bounds.x
            y: bounds.y
            width: root._hasWings ? bounds.width : 0
            height: root._hasWings ? bounds.height : 0

            Region {
                readonly property rect bounds: root._mapRect(root._alongExtent, 0, 2 * root._alongRadius, 2 * root._crossRadius, silhouette.shiftX, silhouette.shiftY)

                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
                x: bounds.x
                y: bounds.y
                width: bounds.width
                height: bounds.height
            }
        }
    }

    Silhouette {}

    // Erode the complete union so the body and wings keep their shared interior.
    Silhouette {
        intersection: Intersection.Intersect
        shiftX: -1
    }

    Silhouette {
        intersection: Intersection.Intersect
        shiftX: 1
    }

    Silhouette {
        intersection: Intersection.Intersect
        shiftY: -1
    }

    Silhouette {
        intersection: Intersection.Intersect
        shiftY: 1
    }
}
