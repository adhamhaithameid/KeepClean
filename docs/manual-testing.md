# Manual Testing Checklist

## Keyboard-Only Mode

1. Launch the app.
2. Open the `Clean` tab.
3. Click `Disable Keyboard`.
4. Confirm the button changes to `Re-enable Keyboard`.
5. Confirm the built-in trackpad remains usable.
6. Click `Re-enable Keyboard`.

## Timed Full-Clean Mode

1. Open the `Settings` tab.
2. Set the duration to 15 seconds for a short verification run.
3. Return to `Clean`.
4. Click `Disable Keyboard + Trackpad for 15 Seconds`.
5. Confirm the countdown appears.
6. Wait for the countdown to complete.
7. Confirm keyboard and trackpad input return automatically.

## Auto-Start Countdown

1. Enable `Start keyboard disable after opening the app`.
2. Relaunch KeepClean.
3. Confirm a 3-second countdown appears.
4. Confirm `Cancel Auto-Start` keeps the keyboard enabled.

## About Tab

1. Open `About`.
2. Confirm the donation button exists.
3. Confirm the repo button exists.
4. Confirm the profile image exists and is clickable.

## Failure Handling

1. Deny HID approval if macOS prompts.
2. Retry a cleaning action.
3. Confirm KeepClean shows a clear error and does not leave the Mac in a broken state.
