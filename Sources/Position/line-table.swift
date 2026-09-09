import Foundation

/// Character-offset-based line table.
///
/// `PositionIndex.offset` is measured in Swift `Character` offsets, matching
/// `String.distance(from:to:)` over `String.Index`.
///
/// This does not use Unicode-scalar, UTF-8, or UTF-16 code-unit offsets.
public struct LineTable:
    Codable,
    Sendable,
    Hashable
{
    let storageLineStarts: [Int]
    let storageLength: Int

    private enum CodingKeys: String, CodingKey {
        case storageLineStarts = "lineStarts"
        case storageLength = "length"
    }

    public init(
        lineStarts: [Int],
        length: Int
    ) {
        storageLineStarts = lineStarts.isEmpty
            ? [0]
            : lineStarts
        storageLength = max(
            0,
            length
        )
    }

    public init(
        text: String
    ) {
        var starts: [Int] = [0]
        var offset = 0

        for character in text {
            offset += 1

            if character == "\n" {
                starts.append(
                    offset
                )
            }
        }

        storageLineStarts = starts
        storageLength = offset
    }

    public var lines: Lines {
        .init(
            root: self
        )
    }

    public var indices: Indices {
        .init(
            root: self
        )
    }


    /// Resolves a character index into its one-based logical line and column.
    public func position(
        at index: PositionIndex,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> Position {
        let index = indices.clamped(
            index
        )
        let line = lines.number(
            containing: index
        )
        let start = lines.start(
            line
        ) ?? PositionIndex(0)

        return Position(
            uncheckedFile: file,
            line: line,
            column: index.offset - start.offset + 1,
            invocation: invocation
        )
    }

    /// Structural mapping of a half-open character range into line/column space.
    ///
    /// For user-facing diagnostics, prefer `displaySpan(for:)`.
    public func span(
        for range: PositionRange,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> PositionSpan {
        PositionSpan(
            uncheckedStart: position(
                at: range.start,
                file: file,
                invocation: invocation
            ),
            uncheckedEnd: position(
                at: range.end,
                file: file,
                invocation: invocation
            )
        )
    }

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

    /// User-facing span for a half-open character range.
    ///
    /// Empty ranges become point spans at `start`. Non-empty ranges resolve
    /// their displayed end to the final included character.
    public func displaySpan(
        for range: PositionRange,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> PositionSpan {
        let start = position(
            at: range.start,
            file: file,
            invocation: invocation
        )

        guard !range.isEmpty else {
            return .point(
                start
            )
        }

        let inclusiveEnd = PositionIndex(
            max(
                range.start.offset,
                range.end.offset - 1
            )
        )
        let end = position(
            at: inclusiveEnd,
            file: file,
            invocation: invocation
        )

        return PositionSpan(
            uncheckedStart: start,
            uncheckedEnd: end
        )
    }

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

    public struct Lines:
        Sendable
    {
        fileprivate let root: LineTable

        fileprivate init(
            root: LineTable
        ) {
            self.root = root
        }

        public var count: Int {
            root.storageLineStarts.count
        }

        public var ranges: Ranges {
            .init(
                root: root
            )
        }

        /// Clamps a one-based logical line number to the table's valid line space.
        public func clamped(
            _ line: Int
        ) -> Int {
            min(
                max(
                    line,
                    1
                ),
                count
            )
        }

        /// Character index at which the requested one-based line begins.
        public func start(
            _ line: Int
        ) -> PositionIndex? {
            guard line >= 1,
                  line <= count else {
                return nil
            }

            return PositionIndex(
                root.storageLineStarts[line - 1]
            )
        }

        /// Exclusive structural end of a line.
        ///
        /// For a non-final line this is the beginning of the following line,
        /// so a structural line range includes its line terminator.
        public func end(
            _ line: Int
        ) -> PositionIndex? {
            guard line >= 1,
                  line <= count else {
                return nil
            }

            if line < count {
                return PositionIndex(
                    root.storageLineStarts[line]
                )
            }

            return PositionIndex(
                root.storageLength
            )
        }

        /// Exclusive end of textual content before the line terminator.
        public func contentEnd(
            _ line: Int
        ) -> PositionIndex? {
            guard let end = end(
                line
            ) else {
                return nil
            }

            guard line < count else {
                return end
            }

            return PositionIndex(
                max(
                    root.storageLineStarts[line - 1],
                    end.offset - 1
                )
            )
        }

        /// One-based logical line containing the supplied character index.
        public func number(
            containing index: PositionIndex
        ) -> Int {
            let target = root.indices
                .clamped(
                    index
                )
                .offset
            var low = 0
            var high = root.storageLineStarts.count

            while low < high {
                let middle = (low + high) / 2

                if root.storageLineStarts[middle] <= target {
                    low = middle + 1
                } else {
                    high = middle
                }
            }

            return max(
                0,
                low - 1
            ) + 1
        }

        public func start(
            containing index: PositionIndex
        ) -> PositionIndex {
            let line = number(
                containing: index
            )

            return PositionIndex(
                root.storageLineStarts[line - 1]
            )
        }

        public func end(
            containing index: PositionIndex
        ) -> PositionIndex {
            let line = number(
                containing: index
            )

            return end(
                line
            ) ?? PositionIndex(
                root.storageLength
            )
        }

        public func contentEnd(
            containing index: PositionIndex
        ) -> PositionIndex {
            let line = number(
                containing: index
            )

            return contentEnd(
                line
            ) ?? PositionIndex(
                root.storageLength
            )
        }

        public struct Ranges:
            Sendable
        {
            fileprivate let root: LineTable

            fileprivate init(
                root: LineTable
            ) {
                self.root = root
            }

            /// Structural range for one logical line, including its terminator
            /// when one exists.
            public func structural(
                _ line: Int
            ) -> PositionRange? {
                guard let start = root.lines.start(
                    line
                ),
                let end = root.lines.end(
                    line
                ) else {
                    return nil
                }

                return PositionRange(
                    uncheckedStart: start,
                    uncheckedEnd: end
                )
            }

            /// Content range for one logical line, excluding its terminator.
            public func content(
                _ line: Int
            ) -> PositionRange? {
                guard let start = root.lines.start(
                    line
                ),
                let end = root.lines.contentEnd(
                    line
                ) else {
                    return nil
                }

                return PositionRange(
                    uncheckedStart: start,
                    uncheckedEnd: end
                )
            }

            /// Structural range spanning an inclusive range of logical lines.
            ///
            /// The result begins at the start of the first line and ends at the
            /// structural end of the last line, including its terminator when one
            /// exists.
            public func structural(
                _ lines: LineRange
            ) -> PositionRange? {
                guard lines.start <= lines.end,
                      let start = root.lines.start(
                        lines.start
                      ),
                      let end = root.lines.end(
                        lines.end
                      ) else {
                    return nil
                }

                return PositionRange(
                    uncheckedStart: start,
                    uncheckedEnd: end
                )
            }

            /// Content range spanning an inclusive range of logical lines.
            ///
            /// Intervening line terminators remain part of the contiguous range;
            /// only the terminator of the final selected line is excluded.
            public func content(
                _ lines: LineRange
            ) -> PositionRange? {
                guard lines.start <= lines.end,
                      let start = root.lines.start(
                        lines.start
                      ),
                      let end = root.lines.contentEnd(
                        lines.end
                      ) else {
                    return nil
                }

                return PositionRange(
                    uncheckedStart: start,
                    uncheckedEnd: end
                )
            }

            public func structural(
                containing index: PositionIndex
            ) -> PositionRange {
                let line = root.lines.number(
                    containing: index
                )

                return structural(
                    line
                ) ?? .point(
                    root.indices.clamped(
                        index
                    )
                )
            }

            public func content(
                containing index: PositionIndex
            ) -> PositionRange {
                let line = root.lines.number(
                    containing: index
                )

                return content(
                    line
                ) ?? .point(
                    root.indices.clamped(
                        index
                    )
                )
            }
        }
    }

    public struct Indices:
        Sendable
    {
        fileprivate let root: LineTable

        fileprivate init(
            root: LineTable
        ) {
            self.root = root
        }

        public var count: Int {
            root.storageLength
        }

        public var start: PositionIndex {
            PositionIndex(0)
        }

        public var end: PositionIndex {
            PositionIndex(
                root.storageLength
            )
        }

        /// Whole half-open character-index space represented by this table.
        public var range: PositionRange {
            PositionRange(
                uncheckedStart: start,
                uncheckedEnd: end
            )
        }

        public func clamped(
            _ index: PositionIndex
        ) -> PositionIndex {
            PositionIndex(
                min(
                    max(
                        index.offset,
                        0
                    ),
                    root.storageLength
                )
            )
        }

        /// Resolves a one-based logical line/column to a character index.
        ///
        /// The exclusive textual end-of-line point is allowed, but a position
        /// cannot cross the line terminator into the following line.
        public func at(
            line: Int,
            column: Int
        ) -> PositionIndex? {
            guard column >= 1,
                  let start = root.lines.start(
                    line
                  ),
                  let end = root.lines.contentEnd(
                    line
                  ) else {
                return nil
            }

            let (
                candidate,
                overflow
            ) = start.offset.addingReportingOverflow(
                column - 1
            )

            guard !overflow,
                  candidate <= end.offset else {
                return nil
            }

            return PositionIndex(
                candidate
            )
        }

        public func at(
            _ position: Position
        ) -> PositionIndex? {
            at(
                line: position.line,
                column: position.column
            )
        }
    }
}
