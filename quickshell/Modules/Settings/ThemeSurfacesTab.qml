import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets

Column {
    id: root

    property var parentModal: null
    readonly property bool borderEnabled: SettingsData.blurBorderEnabled ?? false
    readonly property string windowRadiusKey: CompositorService.supportsLayoutConfig ? CompositorService.configKey + "LayoutRadiusOverride" : ""

    width: parent?.width ?? 0
    spacing: Theme.spacingL

    Component.onCompleted: {
        BlurService.probe();
        CompositorService.refreshDmsWindowFloatingRule();
    }

    ConfigInclude {
        id: windowRulesInclude
        includeKind: "windowrules"
        procTag: "windowrules-include-theme"
        onFixed: {
            if (CompositorService.isMango)
                MangoService.reloadConfig();
            CompositorService.seedDmsWindowFloatingRule();
        }
    }

    function openSurfaceBorderColorPicker() {
        PopoutService.colorPickerModal.selectedColor = SettingsData.blurBorderCustomColor ?? "#ffffff";
        PopoutService.colorPickerModal.pickerTitle = I18n.tr("Surface Border Color");
        PopoutService.colorPickerModal.onColorSelectedCallback = function (color) {
            SettingsData.set("blurBorderCustomColor", color.toString());
        };
        PopoutService.colorPickerModal.open();
    }

    SettingsMaterialCard {
        materialKind: "bar"
        settingKey: "surfaceMaterial_bar"
        title: I18n.tr("Bars and docks")
        description: I18n.tr("Bars, docks and frame")
        tags: ["surface", "material", "opacity", "blur", "highlight", "bar", "dock", "frame"]
    }

    SettingsMaterialCard {
        materialKind: "island"
        settingKey: "surfaceMaterial_island"
        title: I18n.tr("Islands")
        description: I18n.tr("Islands, satellites and free placement")
        tags: ["surface", "material", "opacity", "blur", "highlight", "island", "satellite", "dot"]
    }

    SettingsMaterialCard {
        materialKind: "settings"
        settingKey: "surfaceMaterial_settings"
        title: I18n.tr("Settings windows")
        description: I18n.tr("Settings and native floating windows")
        tags: ["surface", "material", "opacity", "blur", "highlight", "settings", "window", "floating"]
    }

    SettingsMaterialCard {
        materialKind: "popup"
        settingKey: "surfaceMaterial_popup"
        title: I18n.tr("Popups")
        description: I18n.tr("Dash, control center, launcher, notifications and OSD")
        tags: ["surface", "material", "opacity", "blur", "highlight", "popup", "dash", "control center", "launcher", "notification", "osd"]
    }

    SettingsCard {
        tab: "theme"
        tags: ["surface", "popup", "transparency", "opacity", "modal", "corner", "radius", "blur", "background", "glass", "frosted", "shadow", "elevation", "foreground", "layers"]
        title: I18n.tr("Surfaces", "plural noun, settings title, shell surfaces like popouts and modals")
        settingKey: "surfaceStyling"

        SettingsToggleSliderRow {
            tab: "theme"
            tags: ["surface", "popup", "modal", "border", "outline", "edge", "color", "opacity"]
            settingKey: "blurBorderEnabled"
            accessoryKeys: ["blurBorderColor", "blurBorderCustomColor"]
            valueKeys: ["blurBorderOpacity"]
            text: I18n.tr("Border")
            description: I18n.tr("Edge around popups and modals", "surface border toggle description")
            checked: root.borderEnabled
            value: Math.round((SettingsData.blurBorderOpacity ?? 0.35) * 100)
            minimum: 0
            maximum: 100
            onToggled: checked => SettingsData.set("blurBorderEnabled", checked)
            onSliderValueChanged: newValue => SettingsData.set("blurBorderOpacity", newValue / 100)

            accessory: DDropdown {
                id: borderColorMenu
                visible: root.borderEnabled
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Border color")
                showLabel: false
                downKeyOpens: false
                triggerHeight: Theme.switchTrackHeight
                alignPopupRight: !I18n.isRtl
                options: [I18n.tr("Outline", "surface border color"), I18n.tr("Primary", "surface border color"), I18n.tr("Secondary", "surface border color"), I18n.tr("Text Color", "surface border color"), I18n.tr("Custom", "surface border color")]
                optionColorMap: ({
                        [I18n.tr("Outline", "surface border color")]: Theme.outline,
                        [I18n.tr("Primary", "surface border color")]: Theme.primary,
                        [I18n.tr("Secondary", "surface border color")]: Theme.secondary,
                        [I18n.tr("Text Color", "surface border color")]: Theme.surfaceText,
                        [I18n.tr("Custom", "surface border color")]: SettingsData.blurBorderCustomColor ?? "#ffffff"
                    })
                currentValue: {
                    switch (SettingsData.blurBorderColor) {
                    case "primary":
                        return I18n.tr("Primary", "surface border color");
                    case "secondary":
                        return I18n.tr("Secondary", "surface border color");
                    case "surfaceText":
                        return I18n.tr("Text Color", "surface border color");
                    case "custom":
                        return I18n.tr("Custom", "surface border color");
                    default:
                        return I18n.tr("Outline", "surface border color");
                    }
                }
                onValueChanged: value => {
                    switch (value) {
                    case I18n.tr("Primary", "surface border color"):
                        SettingsData.set("blurBorderColor", "primary");
                        return;
                    case I18n.tr("Secondary", "surface border color"):
                        SettingsData.set("blurBorderColor", "secondary");
                        return;
                    case I18n.tr("Text Color", "surface border color"):
                        SettingsData.set("blurBorderColor", "surfaceText");
                        return;
                    case I18n.tr("Custom", "surface border color"):
                        SettingsData.set("blurBorderColor", "custom");
                        root.openSurfaceBorderColorPicker();
                        return;
                    }
                    SettingsData.set("blurBorderColor", "outline");
                }
            }
        }

        SettingsControlledBy {
            visible: SettingsData.connectedFrameModeActive && root.borderEnabled
            parentModal: root.parentModal
            section: "frameBorder"
            settingLabel: I18n.tr("Border")
            reason: I18n.tr("Managed by Frame in Connected Mode")
        }

        SettingsSliderRow {
            tab: "theme"
            tags: ["blur", "background", "transparency", "glass", "frosted", "strength", "radius", "size", "passes", "reach"]
            settingKey: "blurStrength"
            text: I18n.tr("Shared blur strength")
            description: I18n.tr("Applies to all surface categories")
            enabled: BlurService.available
            value: BlurService.strength
            minimum: 16
            maximum: 160
            unit: "px"
            onSliderValueChanged: newValue => SettingsData.set("blurStrength", newValue)
        }

        SettingsNoteRow {
            visible: BlurService.probed && !BlurService.available
            noteIconName: "info"
            tint: Theme.surfaceVariantText
            tintBackground: Theme.surfaceVariantAlpha
            text: I18n.tr("Your compositor does not support ext-background blur")
        }

        SettingsNavRow {
            tab: "theme"
            tags: ["blur", "xray", "compositor", "layout"]
            settingKey: "blurXrayLink"
            visible: BlurService.available && (CompositorService.isNiri || CompositorService.isHyprland)
            title: I18n.tr("Xray options are in Compositor → Layout")
            onClicked: keyboard => root.parentModal?.navigateTo("compositor_layout", keyboard)
        }

        SettingsSplitRow {
            tab: "theme"
            tags: ["elevation", "shadow", "lift", "m3", "material"]
            settingKey: "m3ElevationLink"
            title: I18n.tr("Shadows")
            subtitle: SettingsTabs.page("surface_shadows")?.hint ?? ""
            resetKeys: ["m3ElevationEnabled"]
            checked: SettingsData.m3ElevationEnabled ?? true
            onNavigated: keyboard => root.parentModal?.navigateTo("surface_shadows", keyboard)
            onToggled: checked => SettingsData.set("m3ElevationEnabled", checked)
        }
    }

    SettingsCard {
        tab: "theme"
        tags: ["corner", "radius", "rounded", "square", "fixed", "material", "shape", "window"]
        title: I18n.tr("Corners")
        settingKey: "surfaceCorners"

        SettingsButtonGroupRow {
            tab: "theme"
            tags: ["corner", "radius", "rounded", "square", "fixed", "material", "shape"]
            settingKey: "radiusMode"
            text: I18n.tr("Corner style")
            model: [I18n.tr("Material scale", "corner style: Material shape scale with a strength slider"), I18n.tr("Fixed", "corner style: one radius for every corner")]
            currentIndex: SettingsData.radiusMode === "fixed" ? 1 : 0
            onSelectionChanged: (index, selected) => {
                if (selected)
                    SettingsData.set("radiusMode", index === 1 ? "fixed" : "scale");
            }
        }

        SettingsSliderRow {
            tab: "theme"
            tags: ["corner", "radius", "rounded", "square", "strength"]
            settingKey: "radiusStrength"
            visible: SettingsData.radiusMode !== "fixed"
            text: I18n.tr("Radius strength", "global component corner rounding")
            description: I18n.tr("50 uses Material shapes. Lower values reduce rounding; higher values increase it.", "radius strength slider description")
            minimumLabel: I18n.tr("Square")
            value: SettingsData.radiusStrength
            minimum: 0
            maximum: 100
            unit: ""
            onSliderValueChanged: newValue => SettingsData.set("radiusStrength", newValue)
        }

        SettingsSliderRow {
            tab: "theme"
            tags: ["corner", "radius", "rounded", "square", "fixed"]
            settingKey: "fixedRadius"
            visible: SettingsData.radiusMode === "fixed"
            text: I18n.tr("Corner radius")
            minimumLabel: I18n.tr("Square")
            value: SettingsData.fixedRadius
            minimum: 0
            maximum: 32
            unit: "px"
            onSliderValueChanged: newValue => SettingsData.set("fixedRadius", newValue)
        }

        SettingsToggleSliderRow {
            tab: "theme"
            tags: ["window", "corner", "radius", "match", "follow", "link", "strength", "rounded", "popout", "menu", "modal", "compositor", "niri", "hyprland", "mango"]
            settingKey: "windowRadius"
            text: I18n.tr("Override window radius", "toggle: stop the window radius following the corner style setting")
            visible: root.windowRadiusKey !== ""
            checked: Theme.compositorRadiusOverride >= 0
            value: Theme.windowRadius
            minimum: 0
            maximum: 64
            unit: "px"
            onToggled: checked => SettingsData.set(root.windowRadiusKey, checked ? Math.round(Theme.windowRadius) : -1)
            onSliderDragFinished: finalValue => SettingsData.set(root.windowRadiusKey, finalValue)
        }
    }

    SettingsCard {
        tab: "theme"
        tags: ["floating", "window", "settings", "notepad", "authentication", "polkit", "opacity", "transparency", "foreground", "tile", "tiling", "override"]
        title: I18n.tr("Floating windows")
        settingKey: "floatingWindows"

        SettingsToggleRow {
            tab: "theme"
            tags: ["floating", "window", "title", "bar", "header", "csd", "decoration", "compositor", "kwin", "controls"]
            settingKey: "floatingWindowTitleBars"
            text: I18n.tr("Title bars")
            description: I18n.tr("Off lets the compositor decorate DMS windows. Open windows update when reopened.", "theme floating windows section, title bars toggle description")
            checked: SettingsData.floatingWindowTitleBars
            onToggled: checked => SettingsData.set("floatingWindowTitleBars", checked)
        }

        SettingsToggleRow {
            tab: "theme"
            tags: ["floating", "window", "tile", "tiling", "compositor", "rule", "niri", "hyprland", "mango"]
            settingKey: "dmsWindowsFloating"
            text: I18n.tr("Open floating")
            description: I18n.tr("Adds a compositor window rule so DMS windows such as Settings open floating", "theme floating windows section, open floating toggle description")
            visible: windowRulesInclude.compositorSupported
            checked: CompositorService.dmsWindowFloatingActive
            modified: !checked
            onToggled: checked => {
                CompositorService.setDmsWindowFloatingRule(checked);
                if (checked)
                    windowRulesInclude.check();
            }
        }

        IncludeSetupBanner {
            include: windowRulesInclude
            visibleCondition: windowRulesInclude.compositorSupported && CompositorService.dmsWindowFloatingActive
        }
    }

    SettingsToggleCard {
        tab: "theme"
        tags: ["focus", "ring", "keyboard", "outline", "highlight"]
        settingKey: "focusRingEnabled"
        iconName: "center_focus_strong"
        title: I18n.tr("Focus ring")
        checked: SettingsData.focusRingEnabled
        onToggled: checked => SettingsData.set("focusRingEnabled", checked)

        SettingsSliderRow {
            tab: "theme"
            tags: ["focus", "ring", "thickness", "width"]
            settingKey: "focusRingWidth"
            text: I18n.tr("Thickness")
            value: Math.round(SettingsData.focusRingWidth * 10)
            minimum: 10
            maximum: 40
            step: 5
            decimals: 1
            unit: "px"
            onSliderValueChanged: newValue => SettingsData.set("focusRingWidth", newValue / 10)
        }

        SettingsDropdownRow {
            tab: "theme"
            tags: ["focus", "ring", "color"]
            settingKey: "focusRingColor"
            text: I18n.tr("Color")
            options: [I18n.tr("Primary", "surface border color"), I18n.tr("Secondary", "surface border color"), I18n.tr("Outline", "surface border color"), I18n.tr("Text Color", "surface border color")]
            optionColorMap: ({
                    [I18n.tr("Primary", "surface border color")]: Theme.primary,
                    [I18n.tr("Secondary", "surface border color")]: Theme.secondary,
                    [I18n.tr("Outline", "surface border color")]: Theme.outline,
                    [I18n.tr("Text Color", "surface border color")]: Theme.surfaceText
                })
            currentValue: {
                switch (SettingsData.focusRingColor) {
                case "secondary":
                    return I18n.tr("Secondary", "surface border color");
                case "outline":
                    return I18n.tr("Outline", "surface border color");
                case "surfaceText":
                    return I18n.tr("Text Color", "surface border color");
                default:
                    return I18n.tr("Primary", "surface border color");
                }
            }
            onValueChanged: value => {
                switch (value) {
                case I18n.tr("Secondary", "surface border color"):
                    SettingsData.set("focusRingColor", "secondary");
                    return;
                case I18n.tr("Outline", "surface border color"):
                    SettingsData.set("focusRingColor", "outline");
                    return;
                case I18n.tr("Text Color", "surface border color"):
                    SettingsData.set("focusRingColor", "surfaceText");
                    return;
                }
                SettingsData.set("focusRingColor", "primary");
            }
        }
    }

    SettingsToggleCard {
        tab: "theme"
        tags: ["scroll", "scrollbar", "scrollbars", "list", "page"]
        settingKey: "scrollbarsEnabled"
        iconName: "unfold_more"
        title: I18n.tr("Scrollbars", "theme settings toggle, show scrollbars on lists and pages")
        checked: SettingsData.scrollbarsEnabled
        onToggled: checked => SettingsData.set("scrollbarsEnabled", checked)
    }

    SettingsCard {
        tab: "theme"
        tags: ["button", "color", "accent"]
        title: I18n.tr("Colors")
        settingKey: "surfaceColors"

        SettingsDropdownRow {
            tab: "theme"
            tags: ["button", "color", "primary", "accent", "action"]
            settingKey: "buttonColorMode"
            text: I18n.tr("Button color")
            options: [I18n.tr("Primary", "button color option"), I18n.tr("Primary Container", "button color option"), I18n.tr("Secondary", "button color option"), I18n.tr("Surface Variant", "button color option")]
            optionColorMap: ({
                    [I18n.tr("Primary", "button color option")]: Theme.roleColor("primary"),
                    [I18n.tr("Primary Container", "button color option")]: Theme.roleColor("primaryContainer"),
                    [I18n.tr("Secondary", "button color option")]: Theme.roleColor("secondary"),
                    [I18n.tr("Surface Variant", "button color option")]: Theme.roleColor("surfaceVariant")
                })
            currentValue: {
                switch (SettingsData.buttonColorMode) {
                case "primaryContainer":
                    return I18n.tr("Primary Container", "button color option");
                case "secondary":
                    return I18n.tr("Secondary", "button color option");
                case "surfaceVariant":
                    return I18n.tr("Surface Variant", "button color option");
                default:
                    return I18n.tr("Primary", "button color option");
                }
            }
            onValueChanged: value => {
                switch (value) {
                case I18n.tr("Primary Container", "button color option"):
                    SettingsData.set("buttonColorMode", "primaryContainer");
                    return;
                case I18n.tr("Secondary", "button color option"):
                    SettingsData.set("buttonColorMode", "secondary");
                    return;
                case I18n.tr("Surface Variant", "button color option"):
                    SettingsData.set("buttonColorMode", "surfaceVariant");
                    return;
                }
                SettingsData.set("buttonColorMode", "primary");
            }
        }

        SettingsSliderRow {
            tab: "theme"
            tags: ["container", "accent", "color", "saturation", "tint", "pastel", "primary", "card"]
            settingKey: "containerSaturation"
            text: I18n.tr("Container saturation", "theme setting, saturation of tinted accent containers")
            description: I18n.tr("Tinted cards and badges across the shell", "container saturation setting description")
            value: SettingsData.containerSaturation
            minimum: 0
            maximum: 200
            step: 5
            onSliderValueChanged: newValue => SettingsData.set("containerSaturation", newValue)
        }
    }

    SettingsCard {
        tab: "theme"
        tags: ["control center", "icon", "scale", "size", "tile"]
        title: I18n.tr("Control Center", "Control Center")
        settingKey: "controlCenterIcons"

        SettingsDropdownRow {
            tab: "theme"
            tags: ["control", "center", "tile", "button", "color", "active"]
            settingKey: "controlCenterTileColorMode"
            text: I18n.tr("Tile color", "control center tile color dropdown label")
            options: [I18n.tr("Primary", "tile color option"), I18n.tr("Primary Container", "tile color option"), I18n.tr("Secondary", "tile color option"), I18n.tr("Surface Variant", "tile color option")]
            optionColorMap: ({
                    [I18n.tr("Primary", "tile color option")]: Theme.roleColor("primary"),
                    [I18n.tr("Primary Container", "tile color option")]: Theme.roleColor("primaryContainer"),
                    [I18n.tr("Secondary", "tile color option")]: Theme.roleColor("secondary"),
                    [I18n.tr("Surface Variant", "tile color option")]: Theme.roleColor("surfaceVariant")
                })
            currentValue: {
                switch (SettingsData.controlCenterTileColorMode) {
                case "primaryContainer":
                    return I18n.tr("Primary Container", "tile color option");
                case "secondary":
                    return I18n.tr("Secondary", "tile color option");
                case "surfaceVariant":
                    return I18n.tr("Surface Variant", "tile color option");
                default:
                    return I18n.tr("Primary", "tile color option");
                }
            }
            onValueChanged: value => {
                switch (value) {
                case I18n.tr("Primary Container", "tile color option"):
                    SettingsData.set("controlCenterTileColorMode", "primaryContainer");
                    return;
                case I18n.tr("Secondary", "tile color option"):
                    SettingsData.set("controlCenterTileColorMode", "secondary");
                    return;
                case I18n.tr("Surface Variant", "tile color option"):
                    SettingsData.set("controlCenterTileColorMode", "surfaceVariant");
                    return;
                }
                SettingsData.set("controlCenterTileColorMode", "primary");
            }
        }

        SettingsSliderRow {
            tab: "theme"
            tags: ["control", "center", "icon", "scale", "size", "tile", "header"]
            settingKey: "controlCenterIconScale"
            text: I18n.tr("Icon scale")
            minimum: 50
            maximum: 150
            step: 5
            unit: ""
            decimals: 2
            value: Math.round(SettingsData.controlCenterIconScale * 100)
            onSliderValueChanged: value => SettingsData.set("controlCenterIconScale", value / 100)
        }
    }
}
