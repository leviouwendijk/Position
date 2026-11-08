import Foundation

/// A half-open, one-based line interval. Empty extents represent insertion boundaries.
public struct LineExtent: Sendable, Codable, Hashable {
    public enum Failure: Error, Sendable, Equatable {
        case invalid_start(Int)
        case negative_count(Int)
        case overflow
    }

    public let start: Int
    public let count: Int

    public init(start: Int, count: Int) throws {
        guard start > 0 else { throw Failure.invalid_start(start) }
        guard count >= 0 else { throw Failure.negative_count(count) }
        guard !start.addingReportingOverflow(count).overflow else {
            throw Failure.overflow
        }
        self.start = start
        self.count = count
    }

    private init(validatedStart start: Int, count: Int) {
        self.start = start
        self.count = count
    }

    public var end: Int { start + count }
    public var isEmpty: Bool { count == 0 }

    public var range: LineRange? {
        guard count > 0 else { return nil }
        return .init(uncheckedStart: start, uncheckedEnd: end - 1)
    }

    public func contains(_ line: Int) -> Bool {
        line >= start && line < end
    }

    public func overlaps(_ other: Self) -> Bool {
        max(start, other.start) < min(end, other.end)
    }

    public func intersection(_ other: Self) -> Self? {
        let lower = max(start, other.start)
        let upper = min(end, other.end)
        guard lower < upper else { return nil }
        return .init(validatedStart: lower, count: upper - lower)
    }

    public init(_ range: LineRange) throws {
        try self.init(start: range.start, count: range.end - range.start + 1)
    }

    private enum CodingKeys: String, CodingKey {
        case start
        case count
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let start = try container.decode(Int.self, forKey: .start)
        let count = try container.decode(Int.self, forKey: .count)
        do {
            try self.init(start: start, count: count)
        } catch {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid half-open line extent",
                underlyingError: error
            ))
        }
    }
}
