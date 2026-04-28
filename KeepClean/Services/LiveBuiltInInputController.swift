@preconcurrency import ApplicationServices
import Foundation
import IOKit.hid
import os.log

private let logger = Logger(subsystem: "com.adhamhaithameid.keepclean", category: "InputBlocking")

actor LiveBuiltInInputController: BuiltInInputControlling {
    func prepareMonitoring() async {}

    func availabilitySummary() async -> String {
        let inventory = BuiltInInputInventory.current()

        switch (
            inventory.hasKeyboard, inventory.hasTrackpad,
            KeyboardBlockerResource.isTrusted(prompt: false)
        ) {
        case (true, true, true):
            return "Built-in keyboard and trackpad are ready."
        case (true, true, false):
            return
                "Allow KeepClean in Privacy & Security \u{2192} Accessibility, then reopen it to start cleaning."
        case (true, false, _):
            return "Keyboard found. Waiting for the built-in trackpad."
        case (false, true, _):
            return "Trackpad found. Waiting for the built-in keyboard."
        default:
            return "Waiting for the built-in keyboard and trackpad."
        }
    }

    func lock(target: BuiltInInputTarget) async throws -> InputLockLease {
        var resources: [AnyObject] = []

        do {
            // Accessibility is required for both keyboard and trackpad blocking
            // (both use CGEvent taps which need Accessibility permission).
            guard KeyboardBlockerResource.isTrusted(prompt: true) else {
                logger.error("Accessibility permission NOT granted — cannot create event taps.")
                throw KeepCleanError.permissionDenied(
                    "Allow KeepClean in Privacy & Security \u{2192} Accessibility. Enable it, then reopen the app and try again."
                )
            }
            logger.info("Accessibility permission confirmed.")

            // Input Monitoring is required for active (blocking) event taps.
            // Without it, CGEvent.tapCreate may succeed but returning nil from
            // the callback won't actually block events.
            let hasInputMonitoring = CGPreflightListenEventAccess()
            logger.info("Input Monitoring (CGPreflightListenEventAccess): \(hasInputMonitoring)")
            if !hasInputMonitoring {
                logger.warning(
                    "Input Monitoring NOT granted — event tap will be impotent. Requesting access…")
                CGRequestListenEventAccess()
                throw KeepCleanError.permissionDenied(
                    "Allow KeepClean in Privacy & Security \u{2192} Input Monitoring. Enable it, then try again."
                )
            }

            if target.includesKeyboard {
                logger.info("Creating keyboard blocker…")
                resources.append(try KeyboardBlockerResource.make())
                logger.info("Keyboard blocker created successfully.")
            }

            if target.includesTrackpad {
                logger.info("Creating trackpad blocker…")
                resources.append(try TrackpadBlockerResource.make())
                logger.info("Trackpad blocker created successfully.")
            }

            return InputLockLease(target: target, retainedObjects: resources)
        } catch {
            resources.forEach { object in
                (object as? InputLockResource)?.releaseLock()
            }
            throw error
        }
    }

    // MARK: - Lock with emergency-stop support

    func lock(
        target: BuiltInInputTarget,
        onEmergencyStop: @escaping @Sendable () -> Void
    ) async throws -> InputLockLease {
        var resources: [AnyObject] = []

        do {
            guard KeyboardBlockerResource.isTrusted(prompt: true) else {
                logger.error("Accessibility permission NOT granted — cannot create event taps.")
                throw KeepCleanError.permissionDenied(
                    "Allow KeepClean in Privacy & Security \u{2192} Accessibility. Enable it, then reopen the app and try again."
                )
            }
            logger.info("Accessibility permission confirmed.")

            let hasInputMonitoring = CGPreflightListenEventAccess()
            logger.info("Input Monitoring (CGPreflightListenEventAccess): \(hasInputMonitoring)")
            if !hasInputMonitoring {
                logger.warning(
                    "Input Monitoring NOT granted — event tap will be impotent. Requesting access…")
                CGRequestListenEventAccess()
                throw KeepCleanError.permissionDenied(
                    "Allow KeepClean in Privacy & Security \u{2192} Input Monitoring. Enable it, then try again."
                )
            }

            if target.includesKeyboard {
                logger.info("Creating keyboard blocker with emergency-stop support…")
                resources.append(try KeyboardBlockerResource.make(onEmergencyStop: onEmergencyStop))
                logger.info("Keyboard blocker created successfully.")
            }

            if target.includesTrackpad {
                logger.info("Creating trackpad blocker…")
                resources.append(try TrackpadBlockerResource.make())
                logger.info("Trackpad blocker created successfully.")
            }

            return InputLockLease(target: target, retainedObjects: resources)
        } catch {
            resources.forEach { object in
                (object as? InputLockResource)?.releaseLock()
            }
            throw error
        }
    }
}

// MARK: - Built-in Input Inventory

private struct BuiltInInputInventory {
    let hasKeyboard: Bool
    let hasTrackpad: Bool

    static func current() -> BuiltInInputInventory {
        let keyboardDevices = HIDDeviceSnapshotter.copyBuiltInDevices(
            usagePage: kHIDPage_GenericDesktop,
            usage: kHIDUsage_GD_Keyboard
        )

        let trackpadDevices = HIDDeviceSnapshotter.copyBuiltInTrackpadDevices()

        return BuiltInInputInventory(
            hasKeyboard: !keyboardDevices.isEmpty,
            hasTrackpad: !trackpadDevices.isEmpty
        )
    }
}

// MARK: - HID Device Snapshotter

private enum HIDDeviceSnapshotter {

    /// Returns all built-in HID devices matching the given generic-desktop usage.
    static func copyBuiltInDevices(usagePage: Int, usage: Int) -> [IOHIDDevice] {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let match: [String: Any] = [
            kIOHIDPrimaryUsagePageKey as String: usagePage,
            kIOHIDPrimaryUsageKey as String: usage,
        ]

        IOHIDManagerSetDeviceMatching(manager, match as CFDictionary)
        guard IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess
        else {
            return []
        }
        defer {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }

        let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> ?? []
        return devices.filter(isBuiltIn)
    }

    /// Returns all built-in trackpad devices, checking multiple HID usage combos.
    static func copyBuiltInTrackpadDevices() -> [IOHIDDevice] {
        let candidates: [(Int, Int)] = [
            (kHIDPage_GenericDesktop, kHIDUsage_GD_Mouse),
            (kHIDPage_GenericDesktop, kHIDUsage_GD_Pointer),
            (0x0D, 0x22),
            (0x0D, 0x08),
        ]

        var found: [IOHIDDevice] = []
        for (page, usage) in candidates {
            let devices = copyBuiltInDevices(usagePage: page, usage: usage)
            if !devices.isEmpty {
                found.append(contentsOf: devices)
            }
        }

        var seen = Set<UInt64>()
        return found.filter { device in
            let rawValue = IOHIDDeviceGetProperty(device, kIOHIDLocationIDKey as CFString)
            let id = (rawValue as? NSNumber)?.uint64Value ?? 0
            return seen.insert(id).inserted
        }
    }

    /// Determines if a device is built-in.
    static func isBuiltIn(_ device: IOHIDDevice) -> Bool {
        if let builtIn = IOHIDDeviceGetProperty(device, kIOHIDBuiltInKey as CFString) as? NSNumber,
            builtIn.boolValue
        {
            return true
        }

        let transport =
            IOHIDDeviceGetProperty(device, kIOHIDTransportKey as CFString) as? String ?? ""
        if ["SPI", "I2C", "spi", "i2c"].contains(transport) {
            return true
        }

        let vendorID =
            (IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? NSNumber)?.intValue
            ?? 0
        let product = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? ""
        if vendorID == 0x05AC && product.localizedCaseInsensitiveContains("Internal") {
            return true
        }

        return false
    }
}

// MARK: - Trackpad Blocker Resource

/// Blocks ALL trackpad/mouse input using three combined strategies:
/// 1. CGAssociateMouseAndMouseCursorPosition(false) - disconnects trackpad from cursor
/// 2. CGDisplayHideCursor - hides the cursor
/// 3. CGEvent tap - intercepts and drops ALL mouse/gesture/scroll events
private final class TrackpadBlockerResource: NSObject, InputLockResource {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var runLoop: CFRunLoop?
    private let readySemaphore = DispatchSemaphore(value: 0)
    private var setupError: Error?
    private var cursorHidden = false
    private var cursorDissociated = false

    static func make() throws -> TrackpadBlockerResource {
        let resource = TrackpadBlockerResource()
        resource.start()
        resource.readySemaphore.wait()

        if let error = resource.setupError {
            throw error
        }

        return resource
    }

    func releaseLock() {
        if cursorDissociated {
            CGAssociateMouseAndMouseCursorPosition(1)
            cursorDissociated = false
        }

        if cursorHidden {
            CGDisplayShowCursor(CGMainDisplayID())
            cursorHidden = false
        }

        guard let runLoop else { return }

        let source = self.source
        let tap = self.tap

        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.commonModes.rawValue) {
            if let source {
                CFRunLoopRemoveSource(runLoop, source, .commonModes)
            }
            if let tap {
                CFMachPortInvalidate(tap)
            }
            CFRunLoopStop(runLoop)
        }
        CFRunLoopWakeUp(runLoop)

        self.source = nil
        self.tap = nil
        self.runLoop = nil
    }

    deinit {
        releaseLock()
    }

    private func start() {
        CGAssociateMouseAndMouseCursorPosition(0)
        cursorDissociated = true
        logger.info("Trackpad: cursor dissociated from trackpad.")

        CGDisplayHideCursor(CGMainDisplayID())
        cursorHidden = true
        logger.info("Trackpad: cursor hidden.")

        let thread = Thread(target: self, selector: #selector(runTapLoopObjC), object: nil)
        thread.name = "KeepClean.TrackpadBlocker"
        thread.start()
    }

    @objc
    private func runTapLoopObjC() {
        runTapLoop()
    }

    private func runTapLoop() {
        var mask: CGEventMask = 0
        let mouseTypes: [CGEventType] = [
            .mouseMoved, .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged,
            .scrollWheel, .otherMouseDown, .otherMouseUp, .otherMouseDragged,
        ]
        for t in mouseTypes {
            mask |= CGEventMask(1 << Int(t.rawValue))
        }
        // Gesture events
        for rawType in [18, 29, 30, 31, 32, 34, 37, 38, 39, 40, 61, 62] as [Int] {
            mask |= CGEventMask(1 << rawType)
        }

        let callback = trackpadBlockerCallback as CGEventTapCallBack

        guard
            let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: mask,
                callback: callback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            )
        else {
            setupError = KeepCleanError.permissionDenied(
                "Allow KeepClean in Accessibility to block the trackpad."
            )
            readySemaphore.signal()
            return
        }

        let runLoop = CFRunLoopGetCurrent()
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        self.tap = tap
        self.source = source
        self.runLoop = runLoop

        CFRunLoopAddSource(runLoop, source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        readySemaphore.signal()
        CFRunLoopRun()
    }

    fileprivate func handle(_ type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            logger.warning("Trackpad tap auto-disabled (type=\(type.rawValue)). Re-enabling…")
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            CGAssociateMouseAndMouseCursorPosition(0)
            return Unmanaged.passUnretained(event)
        default:
            return nil
        }
    }
}

// MARK: - Keyboard Blocker Resource

private final class KeyboardBlockerResource: NSObject, InputLockResource {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var runLoop: CFRunLoop?
    private let readySemaphore = DispatchSemaphore(value: 0)
    private var setupError: Error?

    /// Called on the main thread when the emergency stop chord is detected.
    /// Set before calling `start()` so the tap thread sees it from the first event.
    var onEmergencyStop: (@Sendable () -> Void)?

    /// Tracks which character key codes are currently held down.
    /// Used exclusively on the tap thread — no synchronisation needed.
    private var pressedKeyCodes: Set<Int64> = []

    static func isTrusted(prompt: Bool) -> Bool {
        if prompt {
            let options =
                [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }

        return AXIsProcessTrusted()
    }

    static func make(
        onEmergencyStop: (@Sendable () -> Void)? = nil
    ) throws -> KeyboardBlockerResource {
        let resource = KeyboardBlockerResource()
        resource.onEmergencyStop = onEmergencyStop
        resource.start()
        resource.readySemaphore.wait()

        if let error = resource.setupError {
            throw error
        }

        return resource
    }

    func releaseLock() {
        guard let runLoop else {
            return
        }

        let source = self.source
        let tap = self.tap

        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.commonModes.rawValue) {
            if let source {
                CFRunLoopRemoveSource(runLoop, source, .commonModes)
            }

            if let tap {
                CFMachPortInvalidate(tap)
            }

            CFRunLoopStop(runLoop)
        }
        CFRunLoopWakeUp(runLoop)

        self.source = nil
        self.tap = nil
        self.runLoop = nil
    }

    deinit {
        releaseLock()
    }

    private func start() {
        logger.info("Keyboard blocker: starting event tap thread…")
        let thread = Thread(target: self, selector: #selector(runTapLoopObjectiveC), object: nil)
        thread.name = "KeepClean.KeyboardBlocker"
        thread.start()
    }

    @objc
    private func runTapLoopObjectiveC() {
        runTapLoop()
    }

    private func runTapLoop() {
        // Pre-flight: verify Input Monitoring permission on the tap thread.
        let preflightOK = CGPreflightListenEventAccess()
        logger.info("Keyboard tap thread: CGPreflightListenEventAccess = \(preflightOK)")

        // Build keyboard event mask with EXPLICIT Int shifts to avoid
        // type conversion issues between UInt32/Int/CGEventMask(UInt64).
        let keyDownBit = CGEventMask(1 << Int(CGEventType.keyDown.rawValue))  // bit 10
        let keyUpBit = CGEventMask(1 << Int(CGEventType.keyUp.rawValue))  // bit 11
        let flagsBit = CGEventMask(1 << Int(CGEventType.flagsChanged.rawValue))  // bit 12
        let systemDefBit = CGEventMask(1 << 14)  // system-defined

        let mask: CGEventMask = keyDownBit | keyUpBit | flagsBit | systemDefBit
        logger.info("Keyboard tap: event mask = 0x\(String(mask, radix: 16))")

        let callback = keyboardBlockerCallback as CGEventTapCallBack

        // Try HID-level tap first (intercepts events at hardware driver level).
        // Falls back to session-level tap if HID-level fails.
        var createdTap: CFMachPort?
        var tapLevel = "none"

        createdTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        if createdTap != nil {
            tapLevel = "cghidEventTap (HID-level)"
        } else {
            logger.warning(
                "Keyboard: HID-level tap creation failed, falling back to session-level.")
            // Fallback to session-level tap
            createdTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: mask,
                callback: callback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            )
            if createdTap != nil {
                tapLevel = "cgSessionEventTap (session-level)"
            }
        }

        guard let tap = createdTap else {
            logger.error("Keyboard: BOTH tap levels failed. No event tap created.")
            setupError = KeepCleanError.permissionDenied(
                "Allow KeepClean in Accessibility and Input Monitoring to block the keyboard."
            )
            readySemaphore.signal()
            return
        }

        logger.info("Keyboard: event tap created at level: \(tapLevel)")

        let runLoop = CFRunLoopGetCurrent()
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        self.tap = tap
        self.source = source
        self.runLoop = runLoop

        CFRunLoopAddSource(runLoop, source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        logger.info("Keyboard: event tap enabled and run loop starting.")
        readySemaphore.signal()
        CFRunLoopRun()
        logger.info("Keyboard: run loop exited.")
    }

    fileprivate func handle(_ type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Maintain pressed-key set for emergency-stop detection (tap thread only).
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        switch type {
        case .keyDown: pressedKeyCodes.insert(keyCode)
        case .keyUp: pressedKeyCodes.remove(keyCode)
        default: break
        }

        // Emergency stop: if the chord is active, fire the callback on the main
        // thread and pass the event through so modifier state stays consistent.
        if let handler = onEmergencyStop {
            let rawFlags = UInt(event.flags.rawValue)
            if EmergencyStopShortcut.isActive(
                modifierFlagsRawValue: rawFlags,
                pressedKeyCodes: pressedKeyCodes
            ) {
                DispatchQueue.main.async { handler() }
                return Unmanaged.passUnretained(event)
            }
        }

        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // System disabled our tap — re-enable immediately.
            logger.warning("Keyboard tap auto-disabled (type=\(type.rawValue)). Re-enabling…")
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        default:
            // Block all other keyboard events.
            return nil
        }
    }
}

// MARK: - Event Tap Callbacks

private func keyboardBlockerCallback(
    _ proxy: CGEventTapProxy,
    _ type: CGEventType,
    _ event: CGEvent,
    _ userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let blocker = Unmanaged<KeyboardBlockerResource>.fromOpaque(userInfo).takeUnretainedValue()
    return blocker.handle(type, event: event)
}

private func trackpadBlockerCallback(
    _ proxy: CGEventTapProxy,
    _ type: CGEventType,
    _ event: CGEvent,
    _ userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let blocker = Unmanaged<TrackpadBlockerResource>.fromOpaque(userInfo).takeUnretainedValue()
    return blocker.handle(type, event: event)
}
