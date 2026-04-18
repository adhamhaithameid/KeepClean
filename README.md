# KeepClean

KeepClean is a small macOS utility for temporarily disabling the built-in keyboard or the built-in keyboard and trackpad so you can clean them without accidental input.

## What It Does

- `Clean` tab:
  - Disable the built-in keyboard manually, then re-enable it with the trackpad.
  - Disable the built-in keyboard and trackpad for a configurable timed cleaning window.
- `Settings` tab:
  - Configure the full-clean duration between 15 and 180 seconds.
  - Optionally auto-start the keyboard-only cleaning flow after launch, with a visible 3-second cancelable countdown.
- `About` tab:
  - Donation link
  - GitHub repo link
  - GitHub profile image linking to the GitHub profile

## Safety Model

- Keyboard-only mode keeps the built-in trackpad active.
- Full-clean mode uses a helper executable so the timed lock can finish even if the main app window closes.
- The app is intentionally offline. It does not sync, phone home, or use analytics. The only web actions are the three explicit About-tab links opened in the default browser.

## Requirements

- macOS 15 or newer
- Xcode 26.4 or newer recommended
- `xcodegen` for regenerating the project from `project.yml`

## Local Development

```bash
xcodegen generate
./script/build_and_run.sh
```

Run tests:

```bash
xcodebuild -project KeepClean.xcodeproj -scheme KeepClean -destination 'platform=macOS' test
```

## Project Structure

- [project.yml](/Users/adhamhaithameid/Desktop/code/keep-clean/project.yml)
- [KeepClean](/Users/adhamhaithameid/Desktop/code/keep-clean/KeepClean)
- [KeepCleanHelper](/Users/adhamhaithameid/Desktop/code/keep-clean/KeepCleanHelper)
- [KeepCleanTests](/Users/adhamhaithameid/Desktop/code/keep-clean/KeepCleanTests)
- [KeepCleanUITests](/Users/adhamhaithameid/Desktop/code/keep-clean/KeepCleanUITests)
- [docs](/Users/adhamhaithameid/Desktop/code/keep-clean/docs)

## Notes

This project is source-available under PolyForm Noncommercial 1.0.0.
