# Privacy

KeepClean is designed to stay small, local, and easy to trust.

## What KeepClean Does NOT Do

- ❌ No user accounts
- ❌ No analytics or telemetry
- ❌ No cloud sync or storage
- ❌ No background networking
- ❌ No data collection of any kind
- ❌ No auto-update framework

## What KeepClean Does

- ✅ Runs entirely on your Mac
- ✅ Uses Apple's native frameworks (Swift, SwiftUI, ApplicationServices)
- ✅ Stores only your chosen settings (timer duration, auto-start preference) in local UserDefaults
- ✅ The About tab has links to GitHub and support pages — these only open if you click them

## Why It Needs Permissions

KeepClean requests **Accessibility** and **Input Monitoring** permissions so it can intercept and block built-in keyboard events during cleaning. These permissions are:

- Granted through macOS System Settings
- Revocable at any time
- Only used while the app is open and actively blocking input

The app never reads what you type. It only suppresses keyboard/trackpad events — it doesn't log, store, or transmit them.

## Open Source

KeepClean's source code is publicly available on [GitHub](https://github.com/adhamhaithameid/keep-clean) under the [PolyForm Noncommercial 1.0.0](../LICENSE.md) license. You can read every line of code to verify these claims.
