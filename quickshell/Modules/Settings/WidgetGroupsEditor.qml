pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets
import "WidgetGroups.js" as Groups

Column {
    id: root

    required property string barId
    required property string sectionId
    property var parentModal: null
    property var items: []
    property string selectedGroup: ""
    readonly property var config: SettingsData.getBarConfig(barId)
    readonly property string listKey: sectionId + "Widgets"
    readonly property var entries: config?.[listKey] ?? []
    readonly property var groups: config?.widgetGroups ?? ({})
    readonly property var group: Object.prototype.hasOwnProperty.call(groups, selectedGroup) && Groups.plainObject(groups[selectedGroup]) ? groups[selectedGroup] : null
    readonly property int first: entries.findIndex(entry => Groups.groupOf(entry) === selectedGroup && selectedGroup !== "")
    readonly property int last: {
        if (first < 0)
            return -1;
        let end = first;
        while (end + 1 < entries.length && Groups.groupOf(entries[end + 1]) === selectedGroup)
            end++;
        return end;
    }
    visible: group !== null && first >= 0
    spacing: Theme.spacingS

    function save(entries, groups) {
        SettingsData.updateBarConfig(barId, Groups.normalize(Object.assign({}, config, {
            widgetGroups: groups
        }), {
            [listKey]: entries
        }));
    }

    function update(key, value) {
        if (!group)
            return;
        const next = Object.assign({}, groups);
        next[selectedGroup] = Object.assign({}, group, {
            [key]: value
        });
        SettingsData.updateBarConfig(barId, {
            widgetGroups: next
        });
    }

    function ungroup() {
        const next = entries.map(entry => Groups.groupOf(entry) === selectedGroup ? Groups.withGroup(entry, "") : entry);
        const nextGroups = Object.assign({}, groups);
        delete nextGroups[selectedGroup];
        selectedGroup = "";
        save(next, nextGroups);
    }

    SettingsCard {
        width: parent.width
        title: I18n.tr("Group")

        SettingsTextFieldRow {
            text: I18n.tr("Name")
            value: root.group?.name ?? ""
            onEditingFinished: value => root.update("name", value.trim() || I18n.tr("Group"))
        }

        SettingsRow {
            title: I18n.tr("Group")
            DButton {
                text: I18n.tr("Ungroup")
                onClicked: root.ungroup()
            }
        }

        SettingsDropdownRow {
            text: I18n.tr("Style")
            options: [I18n.tr("Pills"), I18n.tr("Segments")]
            currentValue: root.group?.style === "segments" ? options[1] : options[0]
            onValueChanged: value => root.update("style", value === options[1] ? "segments" : "pills")
        }
        SettingsDropdownRow {
            text: I18n.tr("Color")
            options: [I18n.tr("Surface"), I18n.tr("Primary")]
            currentValue: root.group?.tone === "primary" ? options[1] : options[0]
            onValueChanged: value => root.update("tone", value === options[1] ? "primary" : "surface")
        }
        SettingsControlledBy {
            target: "surfaces"
            parentModal: root.parentModal
            section: "surfaceMaterial_bar"
            settingLabel: I18n.tr("Surface material")
        }
        SettingsDropdownRow {
            text: I18n.tr("Overflow")
            options: [I18n.tr("Automatic"), I18n.tr("Bar"), I18n.tr("Always")]
            currentValue: root.group?.overflowMode === "bar" ? options[1] : root.group?.overflowMode === "always" ? options[2] : options[0]
            onValueChanged: value => root.update("overflowMode", value === options[1] ? "bar" : value === options[2] ? "always" : "auto")
        }
        SettingsSliderRow {
            text: I18n.tr("Padding")
            description: I18n.tr("Padding applies along the bar; cross-axis padding adapts to the available thickness.", "widget group padding description")
            minimum: 0
            maximum: Theme.spacingXL
            value: root.group?.padding ?? Theme.spacingXS
            onSliderValueChanged: value => root.update("padding", value)
        }
        SettingsSliderRow {
            text: I18n.tr("Spacing")
            minimum: 0
            maximum: Theme.spacingM
            value: root.group?.spacing ?? Theme.spacingXS
            onSliderValueChanged: value => root.update("spacing", value)
        }
    }
}
