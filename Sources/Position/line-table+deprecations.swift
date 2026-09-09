public extension LineTable {
    /// Legacy flat line-start storage retained for source compatibility.
    ///
    /// Prefer the nested `lines` API for line-oriented coordinate queries.
    @available(*, deprecated, message: "Use the nested lines API instead.")
    var lineStarts: [Int] {
        storageLineStarts
    }

    /// Legacy flat character-count storage retained for source compatibility.
    ///
    /// Prefer `indices.count` for the character-index extent of the table.
    @available(*, deprecated, message: "Use indices.count instead.")
    var length: Int {
        storageLength
    }

    /// Legacy flat line-count API.
    ///
    /// Prefer `lines.count`.
    @available(*, deprecated, message: "Use lines.count instead.")
    var lineCount: Int {
        lines.count
    }

    /// Legacy raw-offset clamping API.
    ///
    /// Prefer `indices.clamped(_:)` with a `PositionIndex`.
    @available(*, deprecated, message: "Use indices.clamped(PositionIndex(_:)) instead.")
    func clampedOffset(
        _ offset: Int
    ) -> Int {
        indices.clamped(
            PositionIndex(offset)
        ).offset
    }

    /// Legacy raw-offset accessor for the beginning of a one-based line.
    ///
    /// Prefer `lines.start(_:)`, which returns a `PositionIndex`.
    @available(*, deprecated, message: "Use lines.start(_:) instead.")
    func lineStartOffset(
        forLine line: Int
    ) -> Int? {
        lines.start(
            line
        )?.offset
    }

    /// Legacy raw-offset accessor for the exclusive structural end of a line.
    ///
    /// Prefer `lines.end(_:)`, which returns a `PositionIndex`.
    @available(*, deprecated, message: "Use lines.end(_:) instead.")
    func lineEndOffset(
        forLine line: Int
    ) -> Int? {
        lines.end(
            line
        )?.offset
    }

    /// Legacy raw-offset line/column resolver.
    ///
    /// Prefer `position(at:)` with a `PositionIndex`.
    @available(*, deprecated, message: "Use position(at: PositionIndex(_:)) instead.")
    func lineAndColumn(
        at offset: Int
    ) -> (line: Int, column: Int) {
        let position = position(
            at: PositionIndex(offset)
        )

        return (
            line: position.line,
            column: position.column
        )
    }

    /// Legacy raw-offset overload retained for source compatibility.
    ///
    /// Prefer the typed `PositionIndex` overload.
    @available(*, deprecated, message: "Use position(at: PositionIndex(_:), file:invocation:) instead.")
    func position(
        at offset: Int,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> Position {
        position(
            at: PositionIndex(offset),
            file: file,
            invocation: invocation
        )
    }

    /// Legacy location spelling and raw-offset overload retained for source compatibility.
    ///
    /// Prefer `position(at:file:invocation:)` with a `PositionIndex`.
    @available(*, deprecated, message: "Use position(at: PositionIndex(_:), file:invocation:) instead.")
    func location(
        at offset: Int,
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> Position {
        position(
            at: PositionIndex(offset),
            file: file,
            invocation: invocation
        )
    }

    /// Legacy location spelling retained for source compatibility.
    @available(*, deprecated, renamed: "position(at:file:invocation:)")
    func location(
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

    /// Legacy raw-offset resolver for a one-based logical line/column.
    ///
    /// Prefer `indices.at(line:column:)`, which returns a `PositionIndex`.
    ///
    /// Semantic note: the nested coordinate API intentionally tightens the old
    /// boundary behavior. The former implementation validated against the
    /// structural line end, so on a non-final terminated line it could admit a
    /// coordinate one character beyond the textual end and across the line
    /// terminator boundary. This compatibility shim adopts the new semantics:
    /// the exclusive textual end-of-line point is valid, but a coordinate may
    /// not cross the line terminator into the following line.
    @available(*, deprecated, message: "Use indices.at(line:column:) instead.")
    func offset(
        line: Int,
        column: Int
    ) -> Int? {
        indices.at(
            line: line,
            column: column
        )?.offset
    }
}
