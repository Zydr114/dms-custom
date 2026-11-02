import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";
import { loadScript } from "./qml-script.mjs";

const store = loadScript(new URL("../Common/settings/SettingsStore.js", import.meta.url));
const spec = loadScript(new URL("../Common/settings/SettingsSpec.js", import.meta.url));
const surface = loadScript(new URL("../Common/SurfaceStyle.js", import.meta.url));
const plain = value => JSON.parse(JSON.stringify(value));

function settingsData() {
    const source = readFileSync(new URL("../Common/SettingsData.qml", import.meta.url), "utf8");
    const context = vm.createContext({ SurfaceStyle: surface, Spec: spec, surfaceProfiles: surface.defaults(), _hooks: {}, saveSettings() {} });
    context.root = context;
    for (const name of ["set", "setSurfaceProfile", "applySurfaceProfileToAll", "resetSurfaceProfile"]) {
        const match = source.match(new RegExp(`^    function ${name}\\([^)]*\\) \\{\\n[\\s\\S]*?^    \\}`, "m"));
        assert.ok(match, `missing ${name}`);
        vm.runInContext(match[0], context);
    }
    return context;
}

test("editing, copying and resetting profiles keeps categories independent", () => {
    const settings = settingsData();
    settings.setSurfaceProfile("bar", { opacity: 0.5, blur: true, highlight: 0.3 });
    settings.setSurfaceProfile("island", { opacity: 0.2 });
    settings.setSurfaceProfile("bar", { opacity: 2, foregroundOpacity: 0 });
    assert.deepEqual(plain(settings.surfaceProfiles.bar), { opacity: 1, blur: true, highlight: 0.3, foregroundOpacity: 0 });
    assert.equal(settings.surfaceProfiles.island.opacity, 0.2);
    assert.equal(settings.surfaceProfiles.popup.opacity, 1);

    settings.applySurfaceProfileToAll("bar");
    for (const kind of ["island", "settings", "popup"])
        assert.deepEqual(plain(settings.surfaceProfiles[kind]), plain(settings.surfaceProfiles.bar));
    for (const kind of ["bar", "island", "settings", "popup"]) {
        settings.surfaceProfiles[kind].opacity = 0.4;
        for (const other of ["bar", "island", "settings", "popup"].filter(value => value !== kind))
            assert.equal(settings.surfaceProfiles[other].opacity, 1);
        settings.surfaceProfiles[kind].opacity = 1;
    }
    settings.surfaceProfiles.bar.opacity = 0.4;

    settings.resetSurfaceProfile("settings");
    assert.deepEqual(plain(settings.surfaceProfiles.settings), plain(surface.defaults().settings));
    assert.equal(settings.surfaceProfiles.bar.opacity, 0.4);
    assert.equal(settings.surfaceProfiles.island.blur, true);
    assert.equal(settings.surfaceProfiles.popup.foregroundOpacity, 0);
});

test("v42 material migration preserves legacy data and resolves effective profiles", () => {
    const original = {
        configVersion: 42, popupTransparency: 100, blurEnabled: true,
        foregroundLayerTransparency: 80, floatingWindowSyncGlobal: false,
        floatingWindowTransparency: 70, floatingWindowForegroundLayers: false,
        notepadTransparencyOverride: 0.3, notepadLastCustomTransparency: 0.4,
        barConfigs: [
            { id: "other", enabled: true, transparency: 0.2, followInterfaceStyle: false },
            { id: "default", enabled: true, transparency: 90, followInterfaceStyle: false, blur: "off", widgetFollowInterfaceStyle: false, widgetTransparency: 0 },
            { id: "dot", enabled: true, dot: true, transparency: 0, followInterfaceStyle: false, blur: "on" }
        ],
        dockConfigs: [{ id: "dock", transparency: 0.6 }],
        unrelated: { untouched: true }
    };
    const migrated = store.migrateToVersion(original, 43);
    assert.deepEqual(plain(migrated.surfaceProfiles), {
        bar: { opacity: 0.9, blur: false, highlight: 0.12, foregroundOpacity: 0 },
        island: { opacity: 0, blur: true, highlight: 0.12, foregroundOpacity: 0.8 },
        settings: { opacity: 0.7, blur: true, highlight: 0.12, foregroundOpacity: 0 },
        popup: { opacity: 1, blur: true, highlight: 0.12, foregroundOpacity: 0.8 }
    });
    assert.deepEqual(plain(migrated.surfaceMaterialBackup.barConfigs), original.barConfigs);
    assert.deepEqual(plain(migrated.surfaceMaterialBackup.dockConfigs), original.dockConfigs);
    assert.equal(migrated.surfaceMaterialBackup.notepadTransparencyOverride, 0.3);
    assert.deepEqual(plain(migrated.unrelated), original.unrelated);
    assert.deepEqual(plain(original.barConfigs), original.barConfigs);
    assert.equal(store.migrateToVersion(migrated, 43), null);
});

test("profile load normalizes malformed partial data and save-load retains explicit values", () => {
    const root = { settingsConfigVersion: 43 };
    store.parse(root, { configVersion: 43, surfaceProfiles: { bar: { opacity: 0, blur: false }, popup: { opacity: 0.7, blur: true, foregroundOpacity: 0 } } });
    assert.deepEqual(plain(root.surfaceProfiles.bar), { opacity: 0, blur: false, highlight: 0.12, foregroundOpacity: 1 });
    assert.deepEqual(plain(root.surfaceProfiles.settings), { opacity: 1, blur: false, highlight: 0.12, foregroundOpacity: 1 });
    const saved = store.toJson(root, new Set());
    const again = { settingsConfigVersion: 43 };
    store.parse(again, plain(saved));
    assert.deepEqual(plain(again.surfaceProfiles), plain(root.surfaceProfiles));
    store.parse(again, { configVersion: 43, surfaceProfiles: [null] });
    assert.equal(again.surfaceProfiles.popup.opacity, 1);
});

test("v42 supplied profiles overlay valid fields and preserve the original material backup", () => {
    const original = {
        configVersion: 42, popupTransparency: 0.8, blurEnabled: true,
        blurStrength: 7, blurBorderEnabled: false, blurBorderColor: "primary",
        blurBorderCustomColor: "#123456", blurBorderOpacity: 0,
        notificationForegroundLayers: false, frameEnabled: true, frameMode: "connected",
        surfaceProfiles: {
            bar: { opacity: 0, blur: false, foregroundOpacity: "bad", highlight: 0 },
            island: { opacity: 2, blur: "off" },
            settings: null,
            popup: { opacity: null, blur: false, highlight: -1, foregroundOpacity: 0 }
        }
    };
    const migrated = store.migrateToVersion(original, 43);
    assert.deepEqual(plain(migrated.surfaceProfiles), {
        bar: { opacity: 0, blur: false, highlight: 0, foregroundOpacity: 1 },
        island: { opacity: 1, blur: true, highlight: 0.12, foregroundOpacity: 1 },
        settings: { opacity: 0.8, blur: true, highlight: 0.12, foregroundOpacity: 1 },
        popup: { opacity: 0.8, blur: false, highlight: 0, foregroundOpacity: 0 }
    });
    for (const key of ["surfaceProfiles", "blurStrength", "blurBorderEnabled", "blurBorderColor", "blurBorderCustomColor", "blurBorderOpacity", "notificationForegroundLayers", "frameEnabled", "frameMode"])
        assert.deepEqual(plain(migrated.surfaceMaterialBackup[key]), original[key], key);
    assert.equal(store.migrateToVersion(migrated, 43), null);
});

test("directly assigned profiles are normalized when saved", () => {
    const root = { settingsConfigVersion: 43 };
    store.parse(root, { configVersion: 43 });
    root.surfaceProfiles = { bar: { opacity: 2, blur: false, foregroundOpacity: 0 }, popup: { blur: true, highlight: -1 } };
    const saved = store.toJson(root, new Set());
    assert.deepEqual(plain(saved.surfaceProfiles.bar), { opacity: 1, blur: false, highlight: 0.12, foregroundOpacity: 0 });
    assert.deepEqual(plain(saved.surfaceProfiles.popup), { opacity: 1, blur: true, highlight: 0, foregroundOpacity: 1 });
    assert.deepEqual(plain(saved.surfaceProfiles.island), { opacity: 1, blur: false, highlight: 0.12, foregroundOpacity: 1 });
});

test("synced floating foreground keeps its legacy layer setting even without blur", () => {
    const migrated = store.migrateToVersion({ configVersion: 42, blurEnabled: false, blurForegroundLayers: false, foregroundLayerTransparency: 0.6 }, 43);
    assert.equal(migrated.surfaceProfiles.popup.foregroundOpacity, 0.6);
    assert.equal(migrated.surfaceProfiles.settings.foregroundOpacity, 0);
});
