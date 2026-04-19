# KeepAwake Design Spec

## Goal

Create a new macOS app named `KeepAwake` by copying the current `KeepClean` repository into a new sibling folder named `/Users/adhamhaithameid/Desktop/code/KeepAwake`, then reworking the product into a menu bar utility that keeps the Mac awake for user-selected durations while preserving the same installation, packaging, and release workflow as `KeepClean`.

## Product Summary

`KeepAwake` is a menu bar app for macOS 13+ that prevents sleep for a chosen duration. The default behavior keeps both the Mac and the display awake. An optional setting allows the display to sleep while keeping the Mac itself awake.

The app lives in the menu bar during normal use and does not show a Dock icon. The settings window opens only when the user selects `Settings` from the menu.

## Core Interaction Model

### Menu Bar Icon

- The menu bar icon is a coffee cup.
- When inactive, the icon is an outlined coffee cup.
- When active, the icon is a filled coffee cup.
- The icon assets should come from outsourced open-source icon sources rather than being hand-drawn in-app.
- The icon should behave as a template-style asset so macOS adapts it naturally for light mode and dark mode.

### Left Click Behavior

- Left click toggles the saved default activation duration.
- If no session is active, left click starts the saved default duration immediately.
- If a session is active, left click stops it immediately.

### Right Click Menu

The right-click menu contains:

- Three prominent square quick actions at the top:
  - `15m`
  - `1h`
  - `Forever`
- A disclosure-style row:
  - `Activate for duration >`
- `Settings` row with an icon
- `Quit` row with an icon

Quick duration selections start immediately.

The `Forever` quick action starts the same indefinite session mode represented elsewhere as `Indefinitely`.

The disclosure row opens the rest of the duration choices:

- `30m`
- `2h`
- `3h`
- `5h`
- `8h`
- `12h`
- `1 day`
- `Indefinitely`

The saved default duration is not changed by quick activation choices. It is changed only from the dedicated `Activation Duration` page.

## Settings Window

The app opens a native macOS window with centered top tabs:

- `Settings`
- `Activation Duration`
- `About`

The UI should follow native macOS visual conventions for the active OS appearance:

- system fonts
- native spacing and roundness
- native checkbox feel
- native slider feel
- light and dark mode support

The design target is macOS-native styling, not a custom cross-platform look.

## Settings Page

The `Settings` page contains:

### General

- `Start at login` checkbox
- `Activate on launch` checkbox

### Battery

- `Deactivate below battery threshold` checkbox
  - When checked, a slider appears below it
  - The slider supports magnetic stopping points at:
    - `10%`
    - `20%`
    - `50%`
    - `70%`
    - `90%`
- `Deactivate in Low Power Mode` checkbox
- `Allow Display Sleep` checkbox

### Footer Action

- `Quit App` button at the bottom

The `Settings` page must not duplicate the duration-management UI, because that belongs on the dedicated `Activation Duration` page.

## Activation Duration Page

The `Activation Duration` page manages available durations and the saved default.

It contains:

- A list of available duration options
- `+` button to add a duration
- `-` button to remove a selected duration
- `Reset Options` button
- `Set as Default` button

### Default and Built-In Presets

Built-in presets:

- `15m`
- `30m`
- `1h`
- `2h`
- `3h`
- `5h`
- `8h`
- `12h`
- `1 day`
- `Indefinitely`

Default preset:

- `15m` initially
- User can change it from this page

### Add Duration Dialog

Adding a duration opens a dialog with three fields:

- `Hours`
- `Minutes`
- `Seconds`

And two actions:

- `Cancel`
- `Add Duration`

This dialog should visually follow the macOS-native style direction approved during brainstorming.

## About Page

The `About` page should match the existing `KeepClean` About page as closely as practical, with changes limited to the app name, app description, and branding assets needed for `KeepAwake`.

Expected content:

- app icon / branding
- app name: `KeepAwake`
- version label
- short description focused on keeping the Mac awake for a chosen duration
- GitHub button
- Donate button
- author credit
- Swift / SwiftUI footer line

## Wake Behavior

### Default Session Behavior

When active, `KeepAwake` prevents both:

- display sleep
- system idle sleep

### Allow Display Sleep

When `Allow Display Sleep` is enabled:

- the Mac should remain awake
- the display is allowed to sleep normally

### Session Types

The app supports exactly one active session at a time:

- inactive
- active until a specific end time
- active indefinitely

If the user starts a new duration while another session is active, the new session replaces the old one.

## Battery and Power Rules

During an active session, the app continuously evaluates the enabled power-safety rules.

### Battery Threshold Rule

If:

- `Deactivate below battery threshold` is enabled
- and the battery percentage falls below the selected threshold

Then:

- the session stops automatically

### Low Power Mode Rule

If:

- `Deactivate in Low Power Mode` is enabled
- and macOS Low Power Mode turns on

Then:

- the session stops automatically

### User Feedback

Automatic deactivation should be communicated clearly through native app status feedback so the stop does not feel unexplained.

## Launch and Lifecycle Behavior

### Start at Login

If enabled, the app launches automatically at user login as a menu bar utility.

### Activate on Launch

If enabled, the app starts the saved default duration automatically when it launches.

### Quit / Stop Safety

On:

- manual stop
- quit
- relaunch
- crash recovery

The app must not leave stale wake assertions behind. The sleep-prevention state should always be cleaned up safely.

## Compatibility

- Minimum supported OS: `macOS 13`
- The app should be suitable for use across Macs supported by that OS target.

## Technical Architecture

The implementation should be decomposed into focused units rather than one large controller.

### Proposed Units

- `WakeAssertionController`
  - owns the actual macOS wake assertions
  - switches assertion behavior based on `Allow Display Sleep`
- `ActivationSessionController`
  - starts, stops, replaces, and expires sessions
  - manages timed and indefinite activation
- `BatteryMonitor`
  - watches battery state and Low Power Mode
- `DurationPresetStore`
  - persists built-in durations, custom durations, and the default preset
- `MenuBarController`
  - owns menu bar interactions, icon state, and menu presentation
- `SettingsViewModel`
  - backs the settings window tabs
- `LaunchAtLoginManager`
  - manages login-item behavior

### Architectural Direction

The app should reuse the `KeepClean` repository structure, release scripts, documentation flow, and project-generation workflow where practical, but the runtime logic should be rewritten around wake assertions instead of input blocking.

## Repository and Packaging Direction

Implementation should:

- create a new sibling folder: `/Users/adhamhaithameid/Desktop/code/KeepAwake`
- copy the `KeepClean` repository contents into it
- rename app, helper, project, bundle identifiers, resources, scripts, docs, and generated artifacts from `KeepClean` to `KeepAwake`
- preserve the same install/build/release/notarization workflow style as the current app

The user also wants a new GitHub repository created for `KeepAwake`.

## Testing Expectations

The new app should include automated coverage for:

- duration preset persistence
- default duration selection
- session start/stop/replace behavior
- indefinite sessions
- battery-threshold auto-deactivation
- Low Power Mode auto-deactivation
- launch behavior flags
- wake assertion cleanup on stop and termination

Manual verification should cover:

- left-click toggle
- right-click quick durations
- disclosure menu for extended durations
- settings window navigation
- login-item behavior
- light mode and dark mode
- menu bar icon state changes
- packaging/install flow parity with `KeepClean`

## Non-Goals

This version does not need:

- multiple concurrent awake sessions
- cloud sync
- analytics
- account systems
- non-macOS platforms
- a custom design language that departs from native macOS styling
