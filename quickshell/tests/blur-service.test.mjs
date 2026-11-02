import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";
import { loadScript } from "./qml-script.mjs";

const SurfaceStyle = loadScript(new URL("../Common/SurfaceStyle.js", import.meta.url));

function service(profiles = {}, available = true) {
    const source = readFileSync(new URL("../Services/BlurService.qml", import.meta.url), "utf8");
    const SettingsData = { blurEnabled: false, frameBlurEnabled: false, surfaceProfiles: profiles };
    const Theme = { surfaceMaterial: kind => SurfaceStyle.profile(SettingsData.surfaceProfiles, kind) };
    const context = vm.createContext({ SettingsData, Theme, available, SurfaceStyle });
    for (const name of ["requestedFor", "enabledFor"]) {
        const match = source.match(new RegExp(`^    function ${name}\\([^)]*\\) \\{\\n[\\s\\S]*?^    \\}`, "m"));
        assert.ok(match, `missing ${name}`);
        vm.runInContext(match[0], context);
    }
    for (const name of ["blurRequested", "enabled"]) {
        const match = source.match(new RegExp(`^    readonly property bool ${name}: (.+)$`, "m"));
        assert.ok(match, `missing ${name}`);
        Object.defineProperty(context, name, { get: () => vm.runInContext(match[1], context) });
    }
    return context;
}

test("bar blur is the default for inherited requests regardless of the old global setting", () => {
    const blur = service();
    for (const bar of [false, true]) {
        blur.SettingsData.surfaceProfiles = { bar: { blur: bar }, popup: { blur: !bar } };
        blur.SettingsData.blurEnabled = !bar;
        assert.equal(blur.requestedFor("on"), true);
        assert.equal(blur.requestedFor("off"), false);
        for (const mode of ["inherit", "unknown", undefined])
            assert.equal(blur.requestedFor(mode), bar);
    }
});

test("a local blur mode inherits the supplied state independently of bar blur", () => {
    const blur = service({ bar: { blur: true } });
    assert.equal(blur.requestedFor("inherit", false), false);
    assert.equal(blur.enabledFor("inherit", false), false);
    assert.equal(blur.enabledFor("on", false), true);
    blur.SettingsData.surfaceProfiles.bar.blur = false;
    assert.equal(blur.requestedFor("inherit", true), true);
    assert.equal(blur.enabledFor("inherit", true), true);
    assert.equal(blur.enabledFor("off", true), false);
    blur.available = false;
    assert.equal(blur.enabledFor("on", true), false);
    blur.available = undefined;
    assert.equal(blur.enabledFor("on", true), false);
});

test("compositor support gates effective blur without changing the requested override", () => {
    const blur = service({ bar: { blur: false } }, false);
    assert.equal(blur.requestedFor("on"), true);
    assert.equal(blur.enabledFor("on"), false);
    blur.available = true;
    assert.equal(blur.enabledFor("on"), true);
    blur.SettingsData.surfaceProfiles.bar.blur = true;
    assert.equal(blur.enabledFor("off"), false);
    assert.equal(blur.enabledFor("inherit"), true);
    blur.available = false;
    assert.equal(blur.enabledFor("inherit"), false);
});

test("each material requests probing and enables blur only when the compositor supports it", () => {
    const blur = service();
    for (const kind of ["bar", "island", "settings", "popup"]) {
        blur.SettingsData.surfaceProfiles = { [kind]: { blur: true } };
        assert.equal(blur.blurRequested, true, kind);
        assert.equal(blur.enabled, true, kind);
        blur.available = false;
        assert.equal(blur.blurRequested, true, kind);
        assert.equal(blur.enabled, false, kind);
        blur.available = true;
    }
    blur.SettingsData.surfaceProfiles = {};
    blur.SettingsData.blurEnabled = true;
    assert.equal(blur.enabled, false);
});
