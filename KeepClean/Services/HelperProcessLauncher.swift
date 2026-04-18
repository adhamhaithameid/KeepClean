import Foundation

struct HelperProcessLauncher {
    private let helperURLProvider: () -> URL?

    init(helperURLProvider: @escaping () -> URL? = HelperProcessLauncher.defaultHelperURL) {
        self.helperURLProvider = helperURLProvider
    }

    func launch(request: HelperLaunchRequest) throws -> Process {
        guard let helperURL = helperURLProvider(), FileManager.default.isExecutableFile(atPath: helperURL.path) else {
            throw KeepCleanError.helperMissing
        }

        let data = try JSONEncoder().encode(request)
        let process = Process()
        process.executableURL = helperURL
        process.arguments = ["--payload-base64", data.base64EncodedString()]
        try process.run()
        return process
    }

    private static func defaultHelperURL() -> URL? {
        Bundle.main.bundleURL.appending(path: "Contents/Helpers/KeepCleanHelper")
    }
}
