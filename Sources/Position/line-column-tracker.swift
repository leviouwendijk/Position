import Foundation

public struct LineColumnSnapshot: Codable, Sendable, Hashable {
    public let line: Int
    public let column: Int
    public let lastConsumedLine: Int
    public let lastConsumedColumn: Int

    public init(
        line: Int,
        column: Int,
        lastConsumedLine: Int,
        lastConsumedColumn: Int
    ) {
        self.line = line
        self.column = column
        self.lastConsumedLine = lastConsumedLine
        self.lastConsumedColumn = lastConsumedColumn
    }
}

/// Tracks human-facing line/column state while consuming source text.
///
/// Important:
/// - This type tracks only line/column state.
/// - It does **not** define or expose a `PositionIndex` offset unit.
/// - Do not assume positions from this tracker are interchangeable with
///   `PositionIndex.offset`. `PositionIndex` is character-offset based.
public struct LineColumnTracker: Codable, Sendable, Hashable {
    public private(set) var line: Int
    public private(set) var column: Int

    public private(set) var lastConsumedLine: Int
    public private(set) var lastConsumedColumn: Int

    public init(
        line: Int = 1,
        column: Int = 1,
        lastConsumedLine: Int = 1,
        lastConsumedColumn: Int = 0
    ) {
        self.line = line
        self.column = column
        self.lastConsumedLine = lastConsumedLine
        self.lastConsumedColumn = lastConsumedColumn
    }

    public mutating func reset() {
        self.line = 1
        self.column = 1
        self.lastConsumedLine = 1
        self.lastConsumedColumn = 0
    }

    @inlinable
    public func snapshot() -> LineColumnSnapshot {
        .init(
            line: line,
            column: column,
            lastConsumedLine: lastConsumedLine,
            lastConsumedColumn: lastConsumedColumn
        )
    }

    public mutating func restore(
        _ snapshot: LineColumnSnapshot
    ) {
        self.line = snapshot.line
        self.column = snapshot.column
        self.lastConsumedLine = snapshot.lastConsumedLine
        self.lastConsumedColumn = snapshot.lastConsumedColumn
    }

    public mutating func advance(
        over scalar: UnicodeScalar
    ) {
        lastConsumedLine = line
        lastConsumedColumn = column

        if scalar == "\n" {
            line += 1
            column = 1
        } else {
            column += 1
        }
    }

    @inlinable
    public mutating func advance<S: Sequence>(
        over scalars: S
    ) where S.Element == UnicodeScalar {
        for scalar in scalars {
            advance(over: scalar)
        }
    }

    @inlinable
    public mutating func advance(
        over text: String
    ) {
        advance(over: text.unicodeScalars)
    }

    @inlinable
    public func currentPosition(
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> Position {
        Position(
            uncheckedFile: file,
            line: line,
            column: column,
            invocation: invocation
        )
    }

    @inlinable
    public func lastConsumedPosition(
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> Position {
        Position(
            uncheckedFile: file,
            line: lastConsumedLine,
            column: lastConsumedColumn,
            invocation: invocation
        )
    }


    /// Point location for "where the cursor is now", useful for EOF.
    @inlinable
    public func pointSpan(
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> PositionSpan {
        let position = currentPosition(
            file: file,
            invocation: invocation
        )

        return .point(position)
    }

    /// Span from a token start to the last consumed character.
    /// If nothing has been consumed after the start, this collapses to a point span.
    @inlinable
    public func span(
        startLine: Int,
        startColumn: Int,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> PositionSpan {
        let consumedAfterStart =
            (lastConsumedLine > startLine)
            || (lastConsumedLine == startLine && lastConsumedColumn >= startColumn)

        let endLine = consumedAfterStart ? lastConsumedLine : startLine
        let endColumn = consumedAfterStart ? lastConsumedColumn : startColumn

        return PositionSpan(
            uncheckedStart: Position(
                uncheckedFile: file,
                line: startLine,
                column: startColumn,
                invocation: invocation
            ),
            uncheckedEnd: Position(
                uncheckedFile: file,
                line: endLine,
                column: endColumn,
                invocation: invocation
            )
        )
    }

    @inlinable
    public func span(
        from snapshot: LineColumnSnapshot,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> PositionSpan {
        span(
            startLine: snapshot.line,
            startColumn: snapshot.column,
            file: file,
            invocation: invocation
        )
    }
}

// public struct LineColumnSnapshot: Codable, Sendable, Hashable {
//     public let line: Int
//     public let column: Int
//     public let lastConsumedLine: Int
//     public let lastConsumedColumn: Int

//     public init(
//         line: Int,
//         column: Int,
//         lastConsumedLine: Int,
//         lastConsumedColumn: Int
//     ) {
//         self.line = line
//         self.column = column
//         self.lastConsumedLine = lastConsumedLine
//         self.lastConsumedColumn = lastConsumedColumn
//     }
// }

// /// Tracks human-facing line/column state while consuming source text.
// ///
// /// Important:
// /// - This type tracks only line/column state.
// /// - It does **not** define or expose a `SourceIndex` offset unit.
// /// - Do not assume positions from this tracker are interchangeable with
// ///   `SourceIndex.offset`. `SourceIndex` is character-offset based.
// public struct LineColumnTracker: Codable, Sendable, Hashable {
//     public private(set) var line: Int
//     public private(set) var column: Int

//     public private(set) var lastConsumedLine: Int
//     public private(set) var lastConsumedColumn: Int

//     public init(
//         line: Int = 1,
//         column: Int = 1,
//         lastConsumedLine: Int = 1,
//         lastConsumedColumn: Int = 0
//     ) {
//         self.line = line
//         self.column = column
//         self.lastConsumedLine = lastConsumedLine
//         self.lastConsumedColumn = lastConsumedColumn
//     }

//     public mutating func reset() {
//         self.line = 1
//         self.column = 1
//         self.lastConsumedLine = 1
//         self.lastConsumedColumn = 0
//     }

//     @inlinable
//     public func snapshot() -> LineColumnSnapshot {
//         .init(
//             line: line,
//             column: column,
//             lastConsumedLine: lastConsumedLine,
//             lastConsumedColumn: lastConsumedColumn
//         )
//     }

//     public mutating func restore(
//         _ snapshot: LineColumnSnapshot
//     ) {
//         self.line = snapshot.line
//         self.column = snapshot.column
//         self.lastConsumedLine = snapshot.lastConsumedLine
//         self.lastConsumedColumn = snapshot.lastConsumedColumn
//     }

//     public mutating func advance(
//         over scalar: UnicodeScalar
//     ) {
//         lastConsumedLine = line
//         lastConsumedColumn = column

//         if scalar == "\n" {
//             line += 1
//             column = 1
//         } else {
//             column += 1
//         }
//     }

//     @inlinable
//     public mutating func advance<S: Sequence>(
//         over scalars: S
//     ) where S.Element == UnicodeScalar {
//         for scalar in scalars {
//             advance(over: scalar)
//         }
//     }

//     @inlinable
//     public mutating func advance(
//         over text: String
//     ) {
//         advance(over: text.unicodeScalars)
//     }

//     @inlinable
//     public func currentLocation(
//         file: String? = nil,
//         invocation: InvocationCallSite? = nil
//     ) -> SourceLocation {
//         SourceLocation(
//             file: file,
//             line: line,
//             column: column,
//             invocation: invocation
//         )
//     }

//     @inlinable
//     public func lastConsumedLocation(
//         file: String? = nil,
//         invocation: InvocationCallSite? = nil
//     ) -> SourceLocation {
//         SourceLocation(
//             file: file,
//             line: lastConsumedLine,
//             column: lastConsumedColumn,
//             invocation: invocation
//         )
//     }

//     /// Point location for "where the cursor is now", useful for EOF.
//     @inlinable
//     public func pointSpan(
//         file: String? = nil,
//         invocation: InvocationCallSite? = nil
//     ) -> SourceSpan {
//         let location = currentLocation(
//             file: file,
//             invocation: invocation
//         )

//         return .point(location)
//     }

//     /// Span from a token start to the last consumed character.
//     /// If nothing has been consumed after the start, this collapses to a point span.
//     @inlinable
//     public func span(
//         startLine: Int,
//         startColumn: Int,
//         file: String? = nil,
//         invocation: InvocationCallSite? = nil
//     ) -> SourceSpan {
//         let consumedAfterStart =
//             (lastConsumedLine > startLine)
//             || (lastConsumedLine == startLine && lastConsumedColumn >= startColumn)

//         let endLine = consumedAfterStart ? lastConsumedLine : startLine
//         let endColumn = consumedAfterStart ? lastConsumedColumn : startColumn

//         return SourceSpan(
//             start: SourceLocation(
//                 file: file,
//                 line: startLine,
//                 column: startColumn,
//                 invocation: invocation
//             ),
//             end: SourceLocation(
//                 file: file,
//                 line: endLine,
//                 column: endColumn,
//                 invocation: invocation
//             )
//         )
//     }

//     @inlinable
//     public func span(
//         from snapshot: LineColumnSnapshot,
//         file: String? = nil,
//         invocation: InvocationCallSite? = nil
//     ) -> SourceSpan {
//         span(
//             startLine: snapshot.line,
//             startColumn: snapshot.column,
//             file: file,
//             invocation: invocation
//         )
//     }
// }
