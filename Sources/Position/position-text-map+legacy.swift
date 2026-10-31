import Foundation

public extension Position.TextMap {
    /// Interpret the legacy, unit-unspecified Position's column using an explicit unit.
    /// This validates the coordinate against this exact source snapshot.
    func coordinate<U: PositionCoordinateUnit>(
        of legacy: Position,
        interpretingColumnsAs unit: U.Type
    ) throws -> Position.Coordinate<U> {
        let coordinate = try Position.Coordinate<U>(
            line: legacy.line,
            column: legacy.column
        )
        _ = try offset(at: coordinate)
        return coordinate
    }

    /// Export a typed coordinate as a legacy Position with optional location metadata.
    /// The coordinate must exist in this source snapshot.
    func position<U: PositionCoordinateUnit>(
        at coordinate: Position.Coordinate<U>,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) throws -> Position {
        _ = try offset(at: coordinate)
        return try Position(
            file: file,
            line: coordinate.line,
            column: coordinate.column,
            invocation: invocation
        )
    }

    /// Interpret the legacy Position's column in a specified encoding, returning
    /// an absolute offset measured in that same encoding.
    func offset<U: PositionCoordinateUnit>(
        at legacy: Position,
        interpretingColumnsAs unit: U.Type
    ) throws -> Position.Offset<U> {
        try offset(at: coordinate(of: legacy, interpretingColumnsAs: U.self))
    }

    /// Convert a legacy, zero-based Character index into a typed absolute offset.
    func offset<U: PositionCoordinateUnit>(
        at index: PositionIndex,
        as unit: U.Type
    ) throws -> Position.Offset<U> {
        let characterOffset = try Position.Offset<Position.Unit.Character>(index.offset)
        return try convert(characterOffset, to: U.self)
    }

    /// Convert a typed absolute offset to a legacy Character index.
    /// Rejects locations inside a grapheme cluster.
    func index<U: PositionCoordinateUnit>(
        at offset: Position.Offset<U>
    ) throws -> PositionIndex {
        let characterOffset = try convert(offset, to: Position.Unit.Character.self)
        return PositionIndex(characterOffset.offset)
    }

    /// Convert a half-open legacy Character range to a half-open typed offset range.
    func range<U: PositionCoordinateUnit>(
        _ range: PositionRange,
        as unit: U.Type
    ) throws -> Range<Position.Offset<U>> {
        let start = try offset(at: range.start, as: U.self)
        let end = try offset(at: range.end, as: U.self)
        guard start <= end else {
            throw TextCoordinateError.reversedRange
        }
        return start..<end
    }

    /// Convert a typed half-open offset range into a legacy Character range.
    /// Both endpoints must align with grapheme-cluster boundaries.
    func legacyRange<U: PositionCoordinateUnit>(
        _ range: Range<Position.Offset<U>>
    ) throws -> PositionRange {
        try PositionRange(
            start: index(at: range.lowerBound),
            end: index(at: range.upperBound)
        )
    }

    /// Convert a half-open typed offset range between coordinate units.
    func convert<From: PositionCoordinateUnit, To: PositionCoordinateUnit>(
        _ range: Range<Position.Offset<From>>,
        to unit: To.Type
    ) throws -> Range<Position.Offset<To>> {
        let start = try convert(range.lowerBound, to: To.self)
        let end = try convert(range.upperBound, to: To.self)
        return start..<end
    }
}
