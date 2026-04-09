import Foundation

/// Character-offset-based line table.
///
/// This matches `PositionIndex.offset`, which is measured using character offsets
/// over `String.Index` / `String.distance(from:to:)`.
///
/// This does **not** use Unicode-scalar count or UTF-8/UTF-16 code-unit count.
public struct LineTable: Codable, Sendable, Hashable {
    public let lineStarts: [Int]
    public let length: Int

    public init(
        lineStarts: [Int],
        length: Int
    ) {
        self.lineStarts = lineStarts.isEmpty ? [0] : lineStarts
        self.length = max(0, length)
    }

    public init(
        text: String
    ) {
        var starts: [Int] = [0]
        var offset = 0

        for character in text {
            offset += 1

            if character == "\n" {
                starts.append(offset)
            }
        }

        self.lineStarts = starts
        self.length = offset
    }

    @inlinable
    public var lineCount: Int {
        lineStarts.count
    }

    @inlinable
    public func clampedOffset(
        _ offset: Int
    ) -> Int {
        min(max(offset, 0), length)
    }

    @inlinable
    public func lineStartOffset(
        forLine line: Int
    ) -> Int? {
        guard line >= 1, line <= lineStarts.count else {
            return nil
        }

        return lineStarts[line - 1]
    }

    /// Exclusive end offset of the line.
    @inlinable
    public func lineEndOffset(
        forLine line: Int
    ) -> Int? {
        guard line >= 1, line <= lineStarts.count else {
            return nil
        }

        if line < lineStarts.count {
            return lineStarts[line]
        }

        return length
    }

    @inlinable
    public func lineAndColumn(
        at offset: Int
    ) -> (line: Int, column: Int) {
        let target = clampedOffset(offset)

        var low = 0
        var high = lineStarts.count

        while low < high {
            let mid = (low + high) / 2

            if lineStarts[mid] <= target {
                low = mid + 1
            } else {
                high = mid
            }
        }

        let lineIndex = max(0, low - 1)
        let line = lineIndex + 1
        let column = (target - lineStarts[lineIndex]) + 1

        return (line, column)
    }

    @inlinable
    public func position(
        at offset: Int,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> Position {
        let resolved = lineAndColumn(at: offset)

        return Position(
            uncheckedFile: file,
            line: resolved.line,
            column: resolved.column,
            invocation: invocation
        )
    }

    @available(*, deprecated, renamed: "position(at:file:invocation:)")
    @inlinable
    public func location(
        at offset: Int,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> Position {
        position(
            at: offset,
            file: file,
            invocation: invocation
        )
    }

    @inlinable
    public func position(
        at index: PositionIndex,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> Position {
        position(
            at: index.offset,
            file: file,
            invocation: invocation
        )
    }

    @available(*, deprecated, renamed: "position(at:file:invocation:)")
    @inlinable
    public func location(
        at index: PositionIndex,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> Position {
        position(
            at: index,
            file: file,
            invocation: invocation
        )
    }

    /// Structural mapping of a half-open range [start, end) into line/column space.
    ///
    /// For user-facing diagnostics, prefer `displaySpan(for:)`.
    @inlinable
    public func span(
        for range: PositionRange,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> PositionSpan {
        PositionSpan(
            uncheckedStart: position(
                at: range.start.offset,
                file: file,
                invocation: invocation
            ),
            uncheckedEnd: position(
                at: range.end.offset,
                file: file,
                invocation: invocation
            )
        )
    }

    @inlinable
    public func span(
        start: PositionIndex,
        end: PositionIndex,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> PositionSpan {
        span(
            for: PositionRange(
                uncheckedStart: start,
                uncheckedEnd: end
            ),
            file: file,
            invocation: invocation
        )
    }

    /// User-facing span for a half-open range [start, end).
    ///
    /// Empty ranges become point spans at `start`.
    /// Non-empty ranges use `end - 1` for the displayed end location,
    /// so the result matches the last included character.
    @inlinable
    public func displaySpan(
        for range: PositionRange,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> PositionSpan {
        let start = position(
            at: range.start.offset,
            file: file,
            invocation: invocation
        )

        guard !range.isEmpty else {
            return .point(start)
        }

        let inclusiveEndOffset = max(
            range.start.offset,
            range.end.offset - 1
        )

        let end = position(
            at: inclusiveEndOffset,
            file: file,
            invocation: invocation
        )

        return PositionSpan(
            uncheckedStart: start,
            uncheckedEnd: end
        )
    }

    @inlinable
    public func displaySpan(
        start: PositionIndex,
        end: PositionIndex,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> PositionSpan {
        displaySpan(
            for: PositionRange(
                uncheckedStart: start,
                uncheckedEnd: end
            ),
            file: file,
            invocation: invocation
        )
    }

    /// Returns a point offset for a 1-based line/column location.
    /// Allows the exclusive end-of-line point.
    @inlinable
    public func offset(
        line: Int,
        column: Int
    ) -> Int? {
        guard column >= 1 else {
            return nil
        }

        guard
            let start = lineStartOffset(forLine: line),
            let end = lineEndOffset(forLine: line)
        else {
            return nil
        }

        let candidate = start + (column - 1)

        guard candidate <= end else {
            return nil
        }

        return candidate
    }
}

// /// Character-offset-based line table.
// ///
// /// This matches `SourceIndex.offset`, which is measured using character offsets
// /// over `String.Index` / `String.distance(from:to:)`.
// ///
// /// This does **not** use Unicode-scalar count or UTF-8/UTF-16 code-unit count.
// public struct LineTable: Codable, Sendable, Hashable {
//     public let lineStarts: [Int]
//     public let length: Int

//     public init(
//         lineStarts: [Int],
//         length: Int
//     ) {
//         self.lineStarts = lineStarts.isEmpty ? [0] : lineStarts
//         self.length = max(0, length)
//     }

//     public init(
//         text: String
//     ) {
//         var starts: [Int] = [0]
//         var offset = 0

//         for character in text {
//             offset += 1

//             if character == "\n" {
//                 starts.append(offset)
//             }
//         }

//         self.lineStarts = starts
//         self.length = offset
//     }

//     @inlinable
//     public var lineCount: Int {
//         lineStarts.count
//     }

//     @inlinable
//     public func clampedOffset(
//         _ offset: Int
//     ) -> Int {
//         min(max(offset, 0), length)
//     }

//     @inlinable
//     public func lineStartOffset(
//         forLine line: Int
//     ) -> Int? {
//         guard line >= 1, line <= lineStarts.count else {
//             return nil
//         }

//         return lineStarts[line - 1]
//     }

//     /// Exclusive end offset of the line.
//     @inlinable
//     public func lineEndOffset(
//         forLine line: Int
//     ) -> Int? {
//         guard line >= 1, line <= lineStarts.count else {
//             return nil
//         }

//         if line < lineStarts.count {
//             return lineStarts[line]
//         }

//         return length
//     }

//     @inlinable
//     public func lineAndColumn(
//         at offset: Int
//     ) -> (line: Int, column: Int) {
//         let target = clampedOffset(offset)

//         var low = 0
//         var high = lineStarts.count

//         while low < high {
//             let mid = (low + high) / 2

//             if lineStarts[mid] <= target {
//                 low = mid + 1
//             } else {
//                 high = mid
//             }
//         }

//         let lineIndex = max(0, low - 1)
//         let line = lineIndex + 1
//         let column = (target - lineStarts[lineIndex]) + 1

//         return (line, column)
//     }

//     @inlinable
//     public func location(
//         at offset: Int,
//         file: String? = nil,
//         invocation: InvocationCallSite? = nil
//     ) -> SourceLocation {
//         let resolved = lineAndColumn(at: offset)

//         return SourceLocation(
//             file: file,
//             line: resolved.line,
//             column: resolved.column,
//             invocation: invocation
//         )
//     }

//     @inlinable
//     public func location(
//         at index: SourceIndex,
//         file: String? = nil,
//         invocation: InvocationCallSite? = nil
//     ) -> SourceLocation {
//         location(
//             at: index.offset,
//             file: file,
//             invocation: invocation
//         )
//     }

//     /// Structural mapping of a half-open range [start, end) into line/column space.
//     ///
//     /// For user-facing diagnostics, prefer `displaySpan(for:)`.
//     @inlinable
//     public func span(
//         for range: SourceRange,
//         file: String? = nil,
//         invocation: InvocationCallSite? = nil
//     ) -> SourceSpan {
//         SourceSpan(
//             start: location(
//                 at: range.start.offset,
//                 file: file,
//                 invocation: invocation
//             ),
//             end: location(
//                 at: range.end.offset,
//                 file: file,
//                 invocation: invocation
//             )
//         )
//     }

//     @inlinable
//     public func span(
//         start: SourceIndex,
//         end: SourceIndex,
//         file: String? = nil,
//         invocation: InvocationCallSite? = nil
//     ) -> SourceSpan {
//         span(
//             for: SourceRange(start: start, end: end),
//             file: file,
//             invocation: invocation
//         )
//     }

//     /// User-facing span for a half-open range [start, end).
//     ///
//     /// Empty ranges become point spans at `start`.
//     /// Non-empty ranges use `end - 1` for the displayed end location,
//     /// so the result matches the last included character.
//     @inlinable
//     public func displaySpan(
//         for range: SourceRange,
//         file: String? = nil,
//         invocation: InvocationCallSite? = nil
//     ) -> SourceSpan {
//         let start = location(
//             at: range.start.offset,
//             file: file,
//             invocation: invocation
//         )

//         guard !range.isEmpty else {
//             return .point(start)
//         }

//         let inclusiveEndOffset = max(
//             range.start.offset,
//             range.end.offset - 1
//         )

//         let end = location(
//             at: inclusiveEndOffset,
//             file: file,
//             invocation: invocation
//         )

//         return SourceSpan(
//             start: start,
//             end: end
//         )
//     }

//     @inlinable
//     public func displaySpan(
//         start: SourceIndex,
//         end: SourceIndex,
//         file: String? = nil,
//         invocation: InvocationCallSite? = nil
//     ) -> SourceSpan {
//         displaySpan(
//             for: SourceRange(start: start, end: end),
//             file: file,
//             invocation: invocation
//         )
//     }

//     /// Returns a point offset for a 1-based line/column location.
//     /// Allows the exclusive end-of-line point.
//     @inlinable
//     public func offset(
//         line: Int,
//         column: Int
//     ) -> Int? {
//         guard column >= 1 else {
//             return nil
//         }

//         guard
//             let start = lineStartOffset(forLine: line),
//             let end = lineEndOffset(forLine: line)
//         else {
//             return nil
//         }

//         let candidate = start + (column - 1)

//         guard candidate <= end else {
//             return nil
//         }

//         return candidate
//     }
// }
