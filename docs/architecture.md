# KeepClean Architecture

## Overview

KeepClean is split into three parts:

1. The macOS app UI, built with SwiftUI.
2. The built-in input controller, which uses CoreHID to detect and seize the built-in keyboard and trackpad.
3. The timed helper executable, which owns strict full-clean sessions so the timeout can complete independently of the main app window.

## Main App

- `KeepCleanApp.swift`
  - Creates the main window.
  - Wires the app delegate termination callback.
- `AppViewModel.swift`
  - Coordinates UI state, auto-start countdowns, manual keyboard sessions, and timed helper launches.
- `RootTabsView.swift`
  - Switches between the `Clean`, `Settings`, and `About` tabs.

## Input Control

- `LiveBuiltInInputController.swift`
  - Uses `HIDDeviceManager` to watch for built-in keyboard and trackpad devices.
  - Maps CoreHID devices into `HIDDeviceSnapshot`.
  - Seizes devices on demand and returns an `InputLockLease`.
- `InputLockLease`
  - Keeps device clients alive while a lock is active.
  - Releasing the lease drops those references so the system can recover the devices.

## Timed Helper

- `KeepCleanHelper/main.swift`
  - Accepts a base64-encoded JSON request.
  - Seizes the built-in keyboard and trackpad.
  - Sleeps until the requested deadline and then exits, allowing the devices to be released.

## Testing Strategy

- Unit tests cover settings, request encoding, device matching, and lock state transitions.
- UI tests run with a mock input controller so they never disable real hardware input.
- Manual testing covers the live built-in input behavior on real hardware.
