import assert from "node:assert/strict";
import test from "node:test";
import { loadScript } from "./qml-script.mjs";

const surface = loadScript(new URL("../Common/SurfaceStyle.js", import.meta.url));
const plain = value => JSON.parse(JSON.stringify(value));

test("material profiles normalize independently and keep explicit zero and false", () => {
    const profiles = surface.normalizeProfiles({
        bar: { opacity: 0, blur: false, highlight: 0, foregroundOpacity: 0 },
        island: { opacity: 2, blur: true, highlight: 1, foregroundOpacity: -1 },
        settings: { opacity: "0.5", blur: "on", highlight: NaN },
        popup: null
    });
    assert.deepEqual(plain(profiles.bar), { opacity: 0, blur: false, highlight: 0, foregroundOpacity: 0 });
    assert.deepEqual(plain(profiles.island), { opacity: 1, blur: true, highlight: 0.4, foregroundOpacity: 0 });
    assert.deepEqual(plain(profiles.settings), { opacity: 1, blur: false, highlight: 0.12, foregroundOpacity: 1 });
    assert.deepEqual(plain(surface.profile(profiles, "unknown")), plain(profiles.popup));
    assert.equal(surface.anyBlur(profiles), true);
    assert.equal(surface.anyBlur({ bar: { blur: "on" } }), false);
    const first = surface.defaults();
    first.bar.opacity = 0;
    assert.equal(first.island.opacity, 1);
    assert.equal(surface.defaults().bar.opacity, 1);
});

test("each category can independently request blur", () => {
    for (const kind of ["bar", "island", "settings", "popup"]) {
        const profiles = surface.defaults();
        profiles[kind].blur = true;
        assert.equal(surface.anyBlur(profiles), true, kind);
        for (const other of ["bar", "island", "settings", "popup"])
            assert.equal(surface.profile(profiles, other).blur, kind === other);
        profiles[kind].blur = false;
        assert.equal(surface.anyBlur(profiles), false, kind);
    }
});

test("opacity inherits only when unset and keeps transparent and opaque overrides", () => {
    for (const inherited of [0, 0.35, 1]) {
        assert.equal(surface.opacity(null, inherited), inherited);
        assert.equal(surface.opacity(undefined, inherited), inherited);
        assert.equal(surface.opacity(0, inherited), 0);
        assert.equal(surface.opacity(1, inherited), 1);
        assert.equal(surface.opacity(0.65, inherited), 0.65);
    }
});

test("invalid opacity cannot leak non-finite values into surface colors", () => {
    for (const invalid of [NaN, Infinity, -Infinity, "0.5", false, {}, []])
        assert.equal(surface.opacity(invalid, 0.4), 0.4);
    assert.equal(surface.opacity(-0.2, 0.4), 0);
    assert.equal(surface.opacity(1.2, 0.4), 1);
    assert.equal(surface.opacity(null, NaN), 1);
    assert.equal(surface.opacity(undefined, -0.1), 0);
});

test("blur overrides inherit the immediate parent rather than a global state", () => {
    for (const parent of [false, true, undefined, 1]) {
        assert.equal(surface.blurRequested("on", parent), true);
        assert.equal(surface.blurRequested("off", parent), false);
        for (const mode of [undefined, null, "inherit", "unknown"])
            assert.equal(surface.blurRequested(mode, parent), parent === true);
    }
});

test("blur and tint are independent with untinted blur and an opaque fast path", () => {
    for (const alpha of [0, 0.3, 1]) {
        assert.equal(surface.opacity(alpha, 0.5), alpha);
        assert.equal(surface.needsBlur(false, alpha), false);
        assert.equal(surface.needsBlur(true, alpha), alpha < 1);
    }
    for (const invalid of [NaN, Infinity, -Infinity, -0.1, "0.3", null])
        assert.equal(surface.needsBlur(true, invalid), false);
});

test("local blur starts a bar request even when global and bar blur are off", () => {
    const config = { blur: "off", leftWidgets: ["clock"], widgetGroups: {} };
    assert.equal(surface.barBlurRequested(config, true), false);
    assert.equal(surface.barBlurRequested(config, false), false);
    for (const section of ["leftWidgets", "centerWidgets", "rightWidgets"]) {
        assert.equal(surface.barBlurRequested({ ...config, [section]: [{ id: "clock", blur: "on" }] }, false), true);
        assert.equal(surface.barBlurRequested({ ...config, [section]: [{ id: "clock", blur: "inherit" }] }, false), false);
    }
    assert.equal(surface.barBlurRequested({ ...config, widgetGroups: { system: { blur: "on" } } }, false), true);
    assert.equal(surface.barBlurRequested({ ...config, widgetGroups: { system: { blur: "off" } } }, false), false);
    assert.equal(surface.barBlurRequested(null, true), true);
    assert.equal(surface.barBlurRequested(null, false), false);
});
