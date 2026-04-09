import Foundation

/// Offset-based half-open range: [start, end).
///
/// `SourceIndex.offset` uses character offsets, matching
/// `String.distance(from:to:)` over `String.Index`.
public struct PositionRange: Codable, Sendable, Hashable, CustomStringConvertible {
    public let start: PositionIndex
    public let end: PositionIndex

    public init(
        start: PositionIndex,
        end: PositionIndex
    ) throws {
        guard end.offset >= start.offset else {
            throw PositionError.invalidRange(
                start: start,
                end: end
            )
        }

        self.start = start
        self.end = end
    }

    @inlinable
    public init(
        uncheckedStart start: PositionIndex,
        uncheckedEnd end: PositionIndex
    ) {
        self.start = start
        self.end = end
    }

    public init(
        _ start: Int,
        _ end: Int
    ) throws {
        try self.init(
            start: .init(start),
            end: .init(end)
        )
    }

    public static func point(
        _ offset: Int
    ) -> Self {
        .init(
            uncheckedStart: .init(offset),
            uncheckedEnd: .init(offset)
        )
    }

    public static func point(
        _ index: PositionIndex
    ) -> Self {
        .init(
            uncheckedStart: index,
            uncheckedEnd: index
        )
    }

    @inlinable
    public var isEmpty: Bool {
        start.offset == end.offset
    }

    @inlinable
    public func contains(
        _ offset: Int
    ) -> Bool {
        offset >= start.offset && offset < end.offset
    }

    public var description: String {
        "\(start.offset)..<\(end.offset)"
    }
}
