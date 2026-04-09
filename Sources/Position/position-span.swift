import Foundation

public struct PositionSpan: CustomStringConvertible, Codable, Sendable, Hashable {
    public let start: Position
    public let end: Position

    public init(
        start: Position,
        end: Position
    ) throws {
        guard end >= start else {
            throw PositionError.invalidSpan(
                start: start,
                end: end
            )
        }

        self.start = start
        self.end = end
    }

    @inlinable
    public init(
        uncheckedStart start: Position,
        uncheckedEnd end: Position
    ) {
        self.start = start
        self.end = end
    }

    @inlinable
    public static func point(
        _ position: Position
    ) -> Self {
        .init(
            uncheckedStart: position,
            uncheckedEnd: position
        )
    }

    @inlinable
    public func contains(
        line: Int,
        column: Int
    ) -> Bool {
        if line < start.line || line > end.line {
            return false
        }

        if start.line == end.line {
            return line == start.line
                && column >= start.column
                && column <= end.column
        }

        if line == start.line {
            return column >= start.column
        }

        if line == end.line {
            return column <= end.column
        }

        return true
    }

    @inlinable
    public func contains(
        _ position: Position
    ) -> Bool {
        contains(
            line: position.line,
            column: position.column
        )
    }

    public var description: String {
        if start.file == end.file, start.line == end.line {
            return "\(start.line):\(start.column)-\(end.column)"
        }

        return "\(start)-\(end)"
    }
}
