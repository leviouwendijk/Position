import Foundation

public typealias PositionLocation = Position

public struct Position: CustomStringConvertible, Codable, Sendable, Hashable, Comparable {
    public let file: String?
    public let line: Int
    public let column: Int
    public let invocation: InvocationCallSite?

    public init(
        file: String? = nil,
        line: Int,
        column: Int,
        invocation: InvocationCallSite? = nil
    ) throws {
        guard line > 0 else {
            throw PositionError.invalidLine(line)
        }

        guard column > 0 else {
            throw PositionError.invalidColumn(column)
        }

        self.file = file
        self.line = line
        self.column = column
        self.invocation = invocation
    }

    @inlinable
    public init(
        uncheckedFile file: String? = nil,
        line: Int,
        column: Int,
        invocation: InvocationCallSite? = nil
    ) {
        self.file = file
        self.line = line
        self.column = column
        self.invocation = invocation
    }

    public var description: String {
        let base = if let file {
            "\(file):\(line):\(column)"
        } else {
            "\(line):\(column)"
        }

        if let invocation, !invocation.description.isEmpty {
            return base + " " + invocation.description
        }

        return base
    }

    @inlinable
    public static func < (
        lhs: Position,
        rhs: Position
    ) -> Bool {
        if lhs.line != rhs.line {
            return lhs.line < rhs.line
        }

        return lhs.column < rhs.column
    }
}

public extension Optional where Wrapped == PositionLocation {
    var describeSuffix: String {
        switch self {
        case .some(let location):
            return " at \(location)"

        case .none:
            return ""
        }
    }
}
