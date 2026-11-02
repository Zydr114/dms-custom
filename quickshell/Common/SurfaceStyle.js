.pragma library

function defaults() {
    return {
        bar: { opacity: 1, blur: false, highlight: 0.12, foregroundOpacity: 1 },
        island: { opacity: 1, blur: false, highlight: 0.12, foregroundOpacity: 1 },
        settings: { opacity: 1, blur: false, highlight: 0.12, foregroundOpacity: 1 },
        popup: { opacity: 1, blur: false, highlight: 0.12, foregroundOpacity: 1 }
    };
}

function profile(profiles, kind) {
    const key = ["bar", "island", "settings", "popup"].includes(kind) ? kind : "popup";
    const value = profiles && typeof profiles === "object" && !Array.isArray(profiles) ? profiles[key] : null;
    const entry = value && typeof value === "object" && !Array.isArray(value) ? value : {};
    return {
        opacity: opacity(entry.opacity, 1),
        blur: entry.blur === true,
        highlight: typeof entry.highlight === "number" && Number.isFinite(entry.highlight) ? Math.max(0, Math.min(0.4, entry.highlight)) : 0.12,
        foregroundOpacity: opacity(entry.foregroundOpacity, 1)
    };
}

function normalizeProfiles(profiles) {
    return {
        bar: profile(profiles, "bar"),
        island: profile(profiles, "island"),
        settings: profile(profiles, "settings"),
        popup: profile(profiles, "popup")
    };
}

function anyBlur(profiles) {
    return ["bar", "island", "settings", "popup"].some(kind => profile(profiles, kind).blur);
}

function opacity(value, inherited) {
    const fallback = typeof inherited === "number" && Number.isFinite(inherited) ? Math.max(0, Math.min(1, inherited)) : 1;
    if (typeof value !== "number" || !Number.isFinite(value))
        return fallback;
    return Math.max(0, Math.min(1, value));
}

function blurRequested(mode, inherited) {
    return mode === "on" || (mode !== "off" && inherited === true);
}

function needsBlur(enabled, alpha) {
    return enabled === true && typeof alpha === "number" && Number.isFinite(alpha) && alpha >= 0 && alpha < 1;
}

function barBlurRequested(config, inherited) {
    if (blurRequested(config?.blur, inherited))
        return true;
    if (Object.values(config?.widgetGroups ?? {}).some(group => group?.blur === "on"))
        return true;
    return ["leftWidgets", "centerWidgets", "rightWidgets"].some(key => Array.isArray(config?.[key]) && config[key].some(entry => entry?.blur === "on"));
}
