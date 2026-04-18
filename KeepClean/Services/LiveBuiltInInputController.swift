@preconcurrency import ApplicationServices
import Foundation
import IOKit.hid

actor LiveBuiltInInputController: BuiltInInputControlling {
    func prepareMonitoring() async {}

    func availabilitySummary() async -> String {
        let inventory = BuiltInInputInventory.current()

        switch (inventory.hasKeyboard, inventory.hasTrackpad, KeyboardBlockerResource.isTrusted(prompt: false)) {
        case (true, true, true):
            return "Built-in keyboard and trackpad are ready."
        case (true, true, false):
            return "Allow KeepClean in Privacy & Security, then reopen it to start cleaning."
        case (true, false, _):
            return "Keyboard found. Waiting for the built-in trackpad."
        case (false, true, _):
            return "Trackpad found. Waiting for the built-in keyboard."
        default:
            return "Waiting for the built-in keyboard and trackpad."
        }
    }

    func lock(target: BuiltInInputTarget) async throws -> InputLockLease {
        let inventory = BuiltInInputInventory.current()

        if target.includesKeyboard && !inventory.hasKeyboard {
            throw KeepCleanError.keyboardUnavailable
        }

        if target.includesTrackpad && !inventory.hasTrackpad {
            throw KeepCleanError.trackpadUnavailable
        }

        var resources: [AnyObject] = []

        do {
            if target.includesKeyboard {
                guard KeyboardBlockerResource.isTrusted(prompt: true) else {
                    throw KeepCleanError.permissionDenied(
                        "Allow KeepClean in Privacy & Security. If macOS asks for Accessibility or Input Monitoring, enable both, then reopen the app and try again."
                    )
                }

                resources.append(try KeyboardBlockerResource.make())
            }

            if target.includesTrackpad {
                resources.append(try BuiltInTrackpadLockResource())
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

private struct BuiltInInputInventory {
    let hasKeyboard: Bool
    let hasTrackpad: Bool

    static func current() -> BuiltInInputInventory {
        let keyboardDevices = HIDDeviceSnapshotter.copyBuiltInDevices(
            usagePage: kHIDPage_GenericDesktop,
            usage: kHIDUsage_GD_Keyboard
        )
        let trackpadDevices = HIDDeviceSnapshotter.copyBuiltInDevices(
            usagePage: kHIDPage_GenericDesktop,
            usage: kHIDUsage_GD_Mouse
        )

        return BuiltInInputInventory(
            hasKeyboard: !keyboardDevices.isEmpty,
            hasTrackpad: !trackpadDevices.isEmpty
        )
    }
}

private enum HIDDeviceSnapshotter {
    static func copyBuiltInDevices(usagePage: Int, usage: Int) -> [IOHIDDevice] {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let match: [String: Any] = [
            kIOHIDPrimaryUsagePageKey as String: usagePage,
            kIOHIDPrimaryUsageKey as String: usage,
            kIOHIDBuiltInKey as String: true,
        ]

        IOHIDManagerSetDeviceMatching(manager, match as CFDictionary)
        guard IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
            return []
        }
        defer {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }

        let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> ?? []
        return devices.filter(isBuiltInKeyboardTrackpad)
    }

    static func isBuiltInKeyboardTrackpad(_ device: IOHIDDevice) -> Bool {
        let product = (IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String) ?? ""
        let builtIn = (IOHIDDeviceGetProperty(device, kIOHIDBuiltInKey as CFString) as? NSNumber)?.boolValue ?? false
        return builtIn && product == "Apple Internal Keyboard / Trackpad"
    }
}

private final class BuiltInTrackpadLockResource: NSObject, InputLockResource {
    private let manager: IOHIDManager
    private var seizedDevices: [IOHIDDevice]

    init(manager: IOHIDManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))) throws {
        self.manager = manager
        self.seizedDevices = []
        super.init()

        let match: [String: Any] = [
            kIOHIDPrimaryUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDPrimaryUsageKey as String: kHIDUsage_GD_Mouse,
            kIOHIDBuiltInKey as String: true,
        ]

        IOHIDManagerSetDeviceMatching(manager, match as CFDictionary)

        let openStatus = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard openStatus == kIOReturnSuccess else {
            throw KeepCleanError.trackpadUnavailable
        }

        let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> ?? []
        let matchingDevices = devices.filter(HIDDeviceSnapshotter.isBuiltInKeyboardTrackpad)
        guard !matchingDevices.isEmpty else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            throw KeepCleanError.trackpadUnavailable
        }

        var lastStatus: IOReturn?

        for device in matchingDevices {
            let status = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
            if status == kIOReturnSuccess {
                seizedDevices.append(device)
            } else {
                lastStatus = status
            }
        }

        guard !seizedDevices.isEmpty else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            throw Self.error(for: lastStatus ?? kIOReturnError)
        }
    }

    func releaseLock() {
        for device in seizedDevices {
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
        }
        seizedDevices.removeAll()
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    deinit {
        releaseLock()
    }

    private static func error(for status: IOReturn) -> KeepCleanError {
        switch status {
        case IOReturn(kIOReturnNotPermitted), IOReturn(kIOReturnNotPrivileged):
            return KeepCleanError.permissionDenied(
                "Allow KeepClean in Privacy & Security. If macOS asks for Input Monitoring, enable it, then reopen the app and try again."
            )
        default:
            return KeepCleanError.seizeFailed("macOS returned \(status) while disabling the trackpad.")
        }
    }
}

private final class KeyboardBlockerResource: NSObject, InputLockResource {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var runLoop: CFRunLoop?
    private let readySemaphore = DispatchSemaphore(value: 0)
    private var setupError: Error?

    static func isTrusted(prompt: Bool) -> Bool {
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }

        return AXIsProcessTrusted()
    }

    static func make() throws -> KeyboardBlockerResource {
        let resource = KeyboardBlockerResource()
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
        let thread = Thread(target: self, selector: #selector(runTapLoopObjectiveC), object: nil)
        thread.name = "KeepClean.KeyboardBlocker"
        thread.start()
    }

    @objc
    private func runTapLoopObjectiveC() {
        runTapLoop()
    }

    private func runTapLoop() {
        let mask = KeyboardEventMask.all
        let callback = keyboardBlockerCallback as CGEventTapCallBack

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            setupError = KeepCleanError.permissionDenied(
                "Allow KeepClean in Privacy & Security. If macOS asks for Accessibility, enable it, then reopen the app and try again."
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
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        case .keyDown, .keyUp, .flagsChanged:
            return nil
        default:
            return Unmanaged.passUnretained(event)
        }
    }
}

private enum KeyboardEventMask {
    static let all: CGEventMask = [
        CGEventType.keyDown,
        .keyUp,
        .flagsChanged,
    ].reduce(0) { partialResult, type in
        partialResult | (1 << type.rawValue)
    }
}

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
