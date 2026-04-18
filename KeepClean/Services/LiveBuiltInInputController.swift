import CoreHID
import Foundation
import OSLog

actor LiveBuiltInInputController: BuiltInInputControlling {
    private let manager = HIDDeviceManager()
    private let logger = Logger(subsystem: "com.adhamhaithameid.keepclean", category: "InputController")
    private var monitorTask: Task<Void, Never>?
    private var deviceReferences: [UInt64: HIDDeviceClient.DeviceReference] = [:]
    private var deviceSnapshots: [UInt64: HIDDeviceSnapshot] = [:]

    func prepareMonitoring() async {
        guard monitorTask == nil else {
            return
        }

        monitorTask = Task { [weak self] in
            await self?.monitorNotifications()
        }
    }

    func availabilitySummary() async -> String {
        let roles = Set(deviceSnapshots.values.compactMap(BuiltInDeviceMatcher.role(for:)))
        switch roles {
        case [.keyboard, .trackpad]:
            return "Built-in keyboard and trackpad are ready."
        case [.keyboard]:
            return "Keyboard found. Waiting for the built-in trackpad."
        case [.trackpad]:
            return "Trackpad found. Waiting for the built-in keyboard."
        default:
            return "Waiting for the built-in keyboard and trackpad. If macOS asks for permission, approve it and try again."
        }
    }

    func lock(target: BuiltInInputTarget) async throws -> InputLockLease {
        await prepareMonitoring()
        try await waitForRequiredDevices(for: target)

        let matchingIDs = deviceSnapshots
            .values
            .filter { snapshot in
                switch target {
                case .keyboard:
                    return BuiltInDeviceMatcher.role(for: snapshot) == .keyboard
                case .trackpad:
                    return BuiltInDeviceMatcher.role(for: snapshot) == .trackpad
                case .keyboardAndTrackpad:
                    return BuiltInDeviceMatcher.role(for: snapshot) != nil
                }
            }
            .map(\.id)

        var clients: [AnyObject] = []

        do {
            for id in matchingIDs {
                guard let reference = deviceReferences[id], let client = HIDDeviceClient(deviceReference: reference) else {
                    continue
                }
                try await client.seizeDevice()
                clients.append(client)
            }
        } catch let error as HIDDeviceError {
            throw map(error: error)
        } catch {
            throw KeepCleanError.seizeFailed(error.localizedDescription)
        }

        guard !clients.isEmpty else {
            throw KeepCleanError.devicesUnavailable
        }

        return InputLockLease(target: target, retainedObjects: clients)
    }

    private func waitForRequiredDevices(for target: BuiltInInputTarget) async throws {
        for _ in 0..<12 {
            let hasKeyboard = deviceSnapshots.values.contains { BuiltInDeviceMatcher.role(for: $0) == .keyboard }
            let hasTrackpad = deviceSnapshots.values.contains { BuiltInDeviceMatcher.role(for: $0) == .trackpad }

            let isReady: Bool
            switch target {
            case .keyboard:
                isReady = hasKeyboard
            case .trackpad:
                isReady = hasTrackpad
            case .keyboardAndTrackpad:
                isReady = hasKeyboard && hasTrackpad
            }

            if isReady {
                return
            }

            try? await Task.sleep(for: .milliseconds(250))
        }

        switch target {
        case .keyboard:
            throw KeepCleanError.keyboardUnavailable
        case .trackpad:
            throw KeepCleanError.trackpadUnavailable
        case .keyboardAndTrackpad:
            throw KeepCleanError.devicesUnavailable
        }
    }

    private func monitorNotifications() async {
        let criteria = [
            HIDDeviceManager.DeviceMatchingCriteria(primaryUsage: .genericDesktop(.keyboard), isBuiltIn: true),
            HIDDeviceManager.DeviceMatchingCriteria(primaryUsage: .genericDesktop(.mouse), isBuiltIn: true),
            HIDDeviceManager.DeviceMatchingCriteria(primaryUsage: .digitizers(.touchPad), isBuiltIn: true),
        ]

        do {
            for try await notification in await manager.monitorNotifications(matchingCriteria: criteria) {
                switch notification {
                case .deviceMatched(let reference):
                    await handleMatchedDevice(reference)
                case .deviceRemoved(let reference):
                    deviceReferences[reference.deviceID] = nil
                    deviceSnapshots[reference.deviceID] = nil
                @unknown default:
                    logger.warning("Received an unknown HID notification.")
                }
            }
        } catch {
            logger.error("CoreHID monitoring failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func handleMatchedDevice(_ reference: HIDDeviceClient.DeviceReference) async {
        guard let client = HIDDeviceClient(deviceReference: reference) else {
            return
        }

        let snapshot = await HIDDeviceSnapshot(
            id: reference.deviceID,
            primaryUsage: map(usage: client.primaryUsage),
            isBuiltIn: client.isBuiltIn,
            transport: map(transport: client.transport),
            productName: client.product ?? "Unknown built-in input"
        )

        guard BuiltInDeviceMatcher.role(for: snapshot) != nil else {
            return
        }

        deviceReferences[reference.deviceID] = reference
        deviceSnapshots[reference.deviceID] = snapshot
    }

    private func map(usage: HIDUsage) -> HIDPrimaryUsage {
        switch usage {
        case .genericDesktop(.keyboard):
            return .keyboard
        case .genericDesktop(.mouse):
            return .mouse
        case .digitizers(.touchPad):
            return .touchPad
        default:
            return .unknown
        }
    }

    private func map(transport: HIDDeviceTransport?) -> HIDTransportKind {
        guard let transport else {
            return .other
        }

        switch transport {
        case .spi:
            return .spi
        case .i2c:
            return .i2c
        case .usb:
            return .usb
        case .bluetooth, .bluetoothAACP, .bluetoothLowEnergy:
            return .bluetooth
        default:
            return .other
        }
    }

    private func map(error: HIDDeviceError) -> KeepCleanError {
        switch error {
        case .notPermitted, .notPrivileged:
            return .permissionDenied("Open the app directly, approve the macOS device prompt, and try again.")
        case .exclusiveAccess, .busy:
            return .seizeFailed("Another process is already holding the device.")
        default:
            return .seizeFailed(error.localizedDescription)
        }
    }
}
