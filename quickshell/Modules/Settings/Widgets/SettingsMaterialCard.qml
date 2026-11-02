import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets

SettingsCard {
    id: root

    required property string materialKind
    property string description: ""
    readonly property var material: Theme.surfaceMaterial(materialKind)

    tab: "theme"

    SettingsNoteRow {
        noteIconName: "info"
        tint: Theme.surfaceVariantText
        tintBackground: Theme.surfaceVariantAlpha
        text: root.description
    }

    SettingsSliderRow {
        text: I18n.tr("Background opacity")
        minimum: 0
        maximum: 100
        value: Math.round(root.material.opacity * 100)
        onSliderValueChanged: value => SettingsData.setSurfaceProfile(root.materialKind, {
                opacity: value / 100
            })
    }

    SettingsToggleRow {
        text: I18n.tr("Background blur")
        description: BlurService.probed && !BlurService.available ? I18n.tr("Your compositor does not support ext-background blur") : ""
        enabled: BlurService.available
        checked: root.material.blur
        onToggled: checked => SettingsData.setSurfaceProfile(root.materialKind, {
                blur: checked
            })
    }

    SettingsToggleSliderRow {
        text: I18n.tr("Edge highlight")
        checked: root.material.highlight > 0
        minimum: 1
        maximum: 40
        value: Math.round(root.material.highlight * 100)
        onToggled: checked => SettingsData.setSurfaceProfile(root.materialKind, {
                highlight: checked ? 0.12 : 0
            })
        onSliderValueChanged: value => SettingsData.setSurfaceProfile(root.materialKind, {
                highlight: value / 100
            })
    }

    SettingsSliderRow {
        text: I18n.tr("Foreground layers")
        minimum: 0
        maximum: 100
        value: Math.round(root.material.foregroundOpacity * 100)
        onSliderValueChanged: value => SettingsData.setSurfaceProfile(root.materialKind, {
                foregroundOpacity: value / 100
            })
    }

    SettingsRow {
        title: I18n.tr("Material")
        DButton {
            text: I18n.tr("Apply to all")
            onClicked: SettingsData.applySurfaceProfileToAll(root.materialKind)
        }
        DButton {
            text: I18n.tr("Reset")
            onClicked: SettingsData.resetSurfaceProfile(root.materialKind)
        }
    }
}
