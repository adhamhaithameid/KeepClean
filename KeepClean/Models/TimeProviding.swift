import Foundation

protocol TimeProviding {
    var now: Date { get }
}

struct SystemClock: TimeProviding {
    var now: Date { Date() }
}

struct TestClock: TimeProviding {
    let now: Date
}
