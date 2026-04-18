# Safety Notes

- Keyboard-only mode is the safest option because the trackpad remains active.
- Full-clean mode always uses a timer and always releases on timeout.
- KeepClean intentionally excludes external keyboards and mice in this version to reduce risk and complexity.
- The helper process exists specifically so a timed full-clean session can recover even if the main window closes.
