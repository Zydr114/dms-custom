# Background materials

Settings → Appearance → Interface style is the single editor for shell background materials. The four profiles are independent:

| Profile | Surfaces |
| --- | --- |
| Bars and docks (`bar`) | Ordinary bars, their capsules/groups, docks and Frame |
| Islands (`island`) | Standalone islands, dots and their satellites, including free placement |
| Settings windows (`settings`) | Settings, native floating shell windows and the floating Notepad |
| Popups (`popup`) | Dash, control center, launcher, notifications, OSD, menus, modal panels and the Notepad slideout |

An island embedded in an ordinary bar follows its bar. Connected surfaces drawn as one physical Frame background follow the Frame's bar material. The compositor accepts one blur region per window; a connected background cannot have different blur strengths inside the same region.

## Controls

Each profile has background opacity (0–100%), background blur, edge highlight (off or 1–40%) and foreground layer opacity (0–100%). Foreground opacity changes nested cards, fields and capsule tones; it does not fade text, icons or the entire window. Apply to all copies all four properties to every category. Reset restores the selected profile to an opaque background, blur off, 12% highlight and full foreground layers.

Shared blur strength controls the compositor's existing blur configuration. It is an approximate logical-pixel reach, not an independent Gaussian radius for each surface. The installed `ext-background-effect-v1` interface supplies blur regions, not per-window radius or saturation. The UI disables blur switches if the capability probe reports no support. Transparency and highlight remain available independently of blur support.

Highlight is a static, light inner edge with a top-to-bottom falloff. It uses existing theme colors and corner geometry. It is separate from ordinary borders, focus outlines, notification accents and elevation shadows. Connected shapes use their final signed-distance boundary so joins do not acquire duplicate rectangular edges. Album art, wallpaper and lockscreen image blur remain separate content effects.

## Bar ownership

Ordinary bars expose a **Bar background** switch in Bar appearance. With the whole background enabled, the bar paints the material once; capsules and groups add a light tone and their existing state/border decoration. With it disabled, individual capsules and group shells own the material. Group children remain transparent over their shell. A group in overflow uses popup material and retains a single outer owner.

The widget **Background** switch still controls whether a capsule is drawn. Island satellite backgrounds similarly decide whether the satellite strip or its individual capsules/groups own material. Frame owns the shared background while Frame styling is active. Zero background opacity is a real transparent material and can still request untinted blur; it is distinct from removing the whole background. Opaque material does not request compositor blur.

## Configuration and migration

Settings version 43 stores:

```json
{
  "surfaceProfiles": {
    "bar": { "opacity": 0.8, "blur": true, "highlight": 0.12, "foregroundOpacity": 1 },
    "island": { "opacity": 0.9, "blur": true, "highlight": 0.12, "foregroundOpacity": 1 },
    "settings": { "opacity": 0.8, "blur": true, "highlight": 0.12, "foregroundOpacity": 1 },
    "popup": { "opacity": 0.8, "blur": true, "highlight": 0.12, "foregroundOpacity": 1 }
  }
}
```

Migration resolves the previous effective values rather than resetting every surface. The enabled ordinary/default bar supplies the bar profile; an enabled island/dot supplies the island profile, with a fallback for configurations without one. Popup and settings profiles preserve the previous global and floating-window values. Previously supplied valid profile fields, including explicit zero and false, take precedence. Numeric inputs are clamped and malformed fields fall back safely.

`surfaceMaterialBackup` retains the original material-related values, including complete bar/dock configurations and old overrides. Migration does not delete those settings. They remain readable for compatibility but no longer override the four profiles in normal rendering. Local capsule/group blur and opacity properties remain inert compatibility inputs for plugins. Old settings controls now navigate to the relevant material card. Configuration version 43 is migrated once; later profile edits do not overwrite the backup.

Before this deployment, the complete settings file and relevant niri fragments were copied to `~/.local/state/dms/backups/background-blur-20261102-224502/`, with SHA-256 hashes in `manifest.json`. To restore the pre-refactor appearance on older source, stop the user shell service, restore the saved settings file, switch source, then restart the service. Restoring the version 42 file while running this source intentionally runs migration again.

## Runtime cost

The refactor adds no polling timer, process, daemon, background capture or socket protocol. Highlight shaders draw only with their owning scene and do not request continuous frames. Blur retains the existing compositor region registries and event-driven refreshes. Covered capsule/group children do not add blur regions. The capability check remains a one-shot process. These are source-level lifetime properties; they are not compositor GPU benchmarks.

## Validation

Acceptance on **2026-11-02**, using the existing niri session and Quickshell 0.3.2:

- `make test-qml` passed the JavaScript logic suite, 31 Qt checks and 38 lock checks. Material regressions cover independent category edits, normalization, apply-to-all without shared object aliases, resetting one category, version 42 migration, backup preservation, sparse/direct-assignment serialization and independent compositor requests. The existing singleton construction-cycle check passes without a new allowlist entry.
- `make lint-qml` passed both shell entrypoints. All 74 changed QML files parsed with Qt 6 `qmlformat`; `git diff --check` passed. The four shaders were generated with `qsb --qt6`. These entrypoint/parse checks do not claim a warning-free per-file dynamic QML lint result.
- The search-index generator produced all four `surfaceMaterial_*` entries, and a second generation was byte-identical. Translation catalogs were not edited.
- The actual compositor reported `ext-background-effect-v1` support. Settings migrated to version 43 and survived a service restart. Screenshots at screen scale 1.25 cover the centralized settings page, opaque settings alongside translucent islands/popups, popup blur on/off, untinted blur at zero opacity, opaque popup fill, normal bars with and without a whole background, grouped capsules, a thin vertical bar, an embedded island, a visible overflow trigger, a standalone dock and connected Frame/control-center geometry. Screenshots and temporary scenario tooling remain local under `/tmp/dms-material-20261102/` and are not distributed with desktop contents.
- Temporary bar/dock/frame configuration was restored. Material edits made through the settings UI during the session were preserved. The complete settings file was byte-identical across the final restart; the original niri effects/layout/window-rules fragments remained byte-identical to their backups. The temporary hot-reload override was removed, and the final user service is active on this checkout with normal hot reload enabled.
- The final startup log contains no material binding/type/shader errors. Changing entire bar configurations during scenarios also exercised pre-existing null-parent/content-loader teardown warnings in ConfirmModal, InputModal, ClipboardHistoryModal and ProcessContextMenu; those unrelated lifecycle issues remain. Existing plugin/icon/portal warnings are not counted as material failures.

The overflow popup was not opened through real pointer input. Full drag/reorder flows, every modal/menu/OSD interaction, Hyprland/Mango/Aqueous behavior and compositor GPU/performance were not interactively accepted. Hyprland Overview has source and QML parse coverage only. The supported strength mapping and region lifecycle retain their existing implementation; no new compositor benchmark is implied.

## Gothic island contour

On **2026-11-03**, standalone Gothic islands switched to one continuous contour for the body and its two concave joins. `GothicSurface` paints fill, notification/focus outline, highlight and elevation shadow in one shader. The old body rectangle and separate join decorations no longer overlap at internal edges. The content host and existing geometry animations remain in place; ordinary pills, embedded islands and Frame retain their rendering paths.

The contour supports all four screen edges, elliptical join radii and independent far corner radii. Join depth is capped against the animated far corners. A continuous approximate distance field avoids the flat-ellipse singularity and the abrupt transition into the straight side. Antialiasing uses shader derivatives capped by the physical pixel footprint, so large derivatives away from the boundary cannot produce false coverage. Fill, outline and highlight share one final coverage factor; an opaque outline or highlight cannot thicken the outside edge by compositing the same coverage repeatedly. Shadow distance remains approximate, rather than an exact Euclidean distance or Gaussian convolution.

`GothicBlurRegion` builds the complete body/joins union before applying a one-logical-pixel discrete cross erosion. This replaces the inset-body plus full-size joins that left mismatched blur at their shared edges. Its attached side extends beyond the window edge before erosion to preserve the first visible row. The component uses a fixed 31 `Region` objects, follows existing geometry bindings and uses the existing blur registration lifecycle. It adds no timer, polling, process, capture or offscreen layer. Integer compositor regions still quantize the floating-point visual contour, especially at fractional screen scale.

Validation used the existing niri desktop, Quickshell 0.3.2, Qt 6.12.0 and screen scale 1.25:

- `make test-qml` passed the JavaScript logic suite, 31 Qt checks and 38 lock checks. `make lint-qml`, parsing all four changed/new QML files with `qmlformat`, focused `GothicBlurRegion` lint and `git diff --check` passed. The shader was generated with `qsb --qt6`. No UI-loading unit tests were added.
- Desktop captures covered compact islands on all four edges, steady expanded/collapsed top islands, large flat joins, elevation shadows, blur off/on, background opacity zero/one and the ordinary pill fallback. The old vertical join seam was absent in the inspected captures. Steady captures used `grim` with island status recorded before and after, because the shell's screenshot action itself collapses the island. Final captures after the shader review checked the opaque highlighted edge and flat joins again.
- A numerical probe checked contour zeroes, finite values and continuity at the straight-side transition for join radii up to 120 by 0.25 logical pixels, the reviewed flat-join false-coverage cases, and the shared coverage alpha bound. These probes and desktop evidence remain local under `/tmp/dms-gothic-island/`; screenshots include desktop contents and are not committed.
- Temporary material, bar and elevation settings were restored while preserving external edits. The complete settings data and checked niri fragments matched their pre-experiment values. A fresh service start was checked for Gothic component, shader, type and binding-loop failures. Rapid earlier configuration changes exposed existing notification teardown callbacks (`setNotificationContentLength` and `setNotificationExpandedHeight`); this patch does not change that lifecycle.

This is a Gothic island fix. General rounded edges on other shell surfaces, controlled solid-wallpaper comparisons, other compositors and GPU performance have not been accepted by this change.
