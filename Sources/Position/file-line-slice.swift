import Foundation

public struct FileLineSlice: Codable, Sendable, Hashable {
    public let file: URL
    public let startLine: Int
    public let lines: [String]

    public init(
        file: URL,
        startLine: Int,
        lines: [String]
    ) {
        self.file = file
        self.startLine = max(1, startLine)
        self.lines = lines
    }

    @inlinable
    public var isEmpty: Bool {
        lines.isEmpty
    }

    @inlinable
    public var endLine: Int {
        guard !lines.isEmpty else {
            return startLine
        }

        return startLine + lines.count - 1
    }

    @inlinable
    public func numberedLines() -> [NumberedLine] {
        lines.enumerated().map { offset, text in
            NumberedLine(
                file: file,
                line: startLine + offset,
                text: text
            )
        }
    }
}
