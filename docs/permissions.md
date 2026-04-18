# Permissions and macOS Prompts

KeepClean uses CoreHID to communicate with the built-in keyboard and trackpad. macOS may require explicit user approval before allowing access to HID devices such as keyboards.

## Expected Behavior

- On the first real device interaction, macOS may show an approval prompt.
- If access is denied, KeepClean surfaces a plain-language error and leaves the Mac usable.
- UI tests use a mock controller and do not request HID access.

## If the App Can’t Lock Input

1. Launch KeepClean directly.
2. Try the keyboard-only action.
3. If macOS prompts for approval, allow it.
4. Retry the action.

If the system still refuses access, relaunch the app and check the status text in the `Clean` tab.
