import Foundation

@main
struct KeepCleanHelperMain {
    static func main() async {
        do {
            let request = try parseRequest()
            let controller = LiveBuiltInInputController()
            await controller.prepareMonitoring()
            let lease = try await controller.lock(target: request.target)
            defer {
                Task {
                    await lease.release()
                }
            }

            let endDate = request.startedAt.addingTimeInterval(TimeInterval(request.durationSeconds))
            let remainingNanoseconds = max(UInt64(endDate.timeIntervalSinceNow * 1_000_000_000), 0)
            try await Task.sleep(nanoseconds: remainingNanoseconds)
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func parseRequest() throws -> HelperLaunchRequest {
        let arguments = CommandLine.arguments
        guard
            let payloadIndex = arguments.firstIndex(of: "--payload-base64"),
            arguments.indices.contains(payloadIndex + 1),
            let data = Data(base64Encoded: arguments[payloadIndex + 1])
        else {
            throw KeepCleanError.invalidHelperArguments
        }

        return try JSONDecoder().decode(HelperLaunchRequest.self, from: data)
    }
}
