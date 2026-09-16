import Foundation

public extension FileLineSlice {
    init?(
        file: URL,
        lines sourceLines: [String],
        range: LineRange
    ) {
        guard !sourceLines.isEmpty else {
            return nil
        }

        let bounds = LineRange(
            uncheckedStart: 1,
            uncheckedEnd: sourceLines.count
        )

        guard let bounded = range.intersection(
            bounds
        ) else {
            return nil
        }

        self.init(
            file: file,
            startLine: bounded.start,
            lines: Array(
                sourceLines[
                    (bounded.start - 1)..<bounded.end
                ]
            )
        )
    }
}
