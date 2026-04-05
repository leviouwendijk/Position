import Foundation

public struct NumberedLine: Codable, Sendable, Hashable {
    public let file: URL
    public let line: Int
    public let text: String

    public init(
        file: URL,
        line: Int,
        text: String
    ) {
        self.file = file
        self.line = line
        self.text = text
    }
}
