import Foundation

/// Character-offset index into a `String`.
///
/// The offset unit matches `String.distance(from:to:)` over `String.Index`,
/// not Unicode-scalar count and not UTF-8/UTF-16 code-unit count.
public struct PositionIndex: Codable, Sendable, Hashable, CustomStringConvertible, Comparable {
    public let offset: Int

    @inlinable
    public init(
        _ offset: Int
    ) {
        self.offset = offset
    }

    public var description: String {
        "\(offset)"
    }

    /// Returns an index advanced by the supplied character-offset distance.
    @inlinable
    public func advanced(
        by distance: Int
    ) -> Self {
        .init(
            offset + distance
        )
    }

    /// Returns the character-offset distance from this index to another index.
    @inlinable
    public func distance(
        to other: Self
    ) -> Int {
        other.offset - offset
    }

    @inlinable
    public static func < (
        lhs: PositionIndex,
        rhs: PositionIndex
    ) -> Bool {
        lhs.offset < rhs.offset
    }
}
