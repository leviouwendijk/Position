import Foundation

public struct LineRange: Codable, Sendable, Hashable, CustomStringConvertible {
    public let start: Int
    public let end: Int

    public init(
        start: Int,
        end: Int
    ) throws {
        guard start > 0 else {
            throw PositionError.invalidLine(start)
        }

        guard end > 0 else {
            throw PositionError.invalidLine(end)
        }

        guard end >= start else {
            throw PositionError.invalidLineRange(
                start: start,
                end: end
            )
        }

        self.start = start
        self.end = end
    }

    @inlinable
    public init(
        uncheckedStart start: Int,
        uncheckedEnd end: Int
    ) {
        self.start = start
        self.end = end
    }

    public init(
        _ start: Int,
        _ end: Int
    ) throws {
        try self.init(
            start: start,
            end: end
        )
    }

    @inlinable
    public var closedRange: ClosedRange<Int> {
        start...end
    }

    @inlinable
    public func contains(
        _ line: Int
    ) -> Bool {
        closedRange.contains(line)
    }

    public var description: String {
        "\(start)..\(end)"
    }
}
