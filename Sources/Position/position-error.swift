import Foundation

public enum PositionError: Error, LocalizedError, Sendable, Equatable {
    case invalidLine(Int)
    case invalidColumn(Int)
    case invalidRange(start: PositionIndex, end: PositionIndex)
    case invalidSpan(start: Position, end: Position)
    case invalidLineRange(start: Int, end: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidLine(let line):
            return "Invalid line \(line). Line must be greater than zero."

        case .invalidColumn(let column):
            return "Invalid column \(column). Column must be greater than zero."

        case .invalidRange(let start, let end):
            return "Invalid range \(start.offset)..<\(end.offset). End must not precede start."

        case .invalidSpan(let start, let end):
            return "Invalid span \(start)-\(end). End must not precede start."

        case .invalidLineRange(let start, let end):
            return "Invalid line range \(start)..\(end). End must not precede start."
        }
    }
}
