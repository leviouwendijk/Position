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

public extension PositionRange {
    /// Creates a typed character range from an ordinary half-open offset range.
    init(
        _ offsets: Range<Int>
    ) {
        self.init(
            uncheckedStart: PositionIndex(
                offsets.lowerBound
            ),
            uncheckedEnd: PositionIndex(
                offsets.upperBound
            )
        )
    }

    var offsets: Range<Int> {
        start.offset..<end.offset
    }

    var count: Int {
        end.offset - start.offset
    }

    func contains(
        _ index: PositionIndex
    ) -> Bool {
        contains(
            index.offset
        )
    }

    /// Clamps this range to the supplied half-open bounds.
    ///
    /// A range entirely outside the bounds collapses to an empty range at the
    /// nearest boundary.
    func clamped(
        to bounds: PositionRange
    ) -> PositionRange {
        let clampedStart = min(
            max(
                start.offset,
                bounds.start.offset
            ),
            bounds.end.offset
        )
        let clampedEnd = min(
            max(
                end.offset,
                clampedStart
            ),
            bounds.end.offset
        )

        return PositionRange(
            uncheckedStart: PositionIndex(
                clampedStart
            ),
            uncheckedEnd: PositionIndex(
                clampedEnd
            )
        )
    }

    /// Returns the non-empty overlap with another half-open range.
    func intersection(
        with other: PositionRange
    ) -> PositionRange? {
        let start = max(
            start.offset,
            other.start.offset
        )
        let end = min(
            end.offset,
            other.end.offset
        )

        guard start < end else {
            return nil
        }

        return PositionRange(
            uncheckedStart: PositionIndex(
                start
            ),
            uncheckedEnd: PositionIndex(
                end
            )
        )
    }
}
