import Foundation

/// Offset-based half-open range: [start, end).
///
/// `SourceIndex.offset` uses character offsets, matching
/// `String.distance(from:to:)` over `String.Index`.
public struct SourceRange: Codable, Sendable, Hashable, CustomStringConvertible {
    public let start: SourceIndex
    public let end: SourceIndex

    @inlinable
    public init(
        start: SourceIndex,
        end: SourceIndex
    ) {
        self.start = start
        self.end = end
    }

    @inlinable
    public init(
        _ start: Int,
        _ end: Int
    ) {
        self.start = .init(start)
        self.end = .init(end)
    }

    @inlinable
    public static func point(
        _ offset: Int
    ) -> Self {
        .init(offset, offset)
    }

    @inlinable
    public static func point(
        _ index: SourceIndex
    ) -> Self {
        .init(
            start: index,
            end: index
        )
    }

    @inlinable
    public var isEmpty: Bool {
        start.offset >= end.offset
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
