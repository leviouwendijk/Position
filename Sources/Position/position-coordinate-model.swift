import Foundation

/// Stateless measurement units. A coordinate's unit is fixed by its type.
public protocol PositionCoordinateUnit: Sendable {
    static var metric: Position.Unit.Metric { get }
}

public extension Position {
    enum Unit {
        public enum Metric: Sendable {
            case utf8
            case utf16
            case utf32
            case character
        }

        public enum UTF8: PositionCoordinateUnit {
            public static let metric: Metric = .utf8
        }

        public enum UTF16: PositionCoordinateUnit {
            public static let metric: Metric = .utf16
        }

        public enum UTF32: PositionCoordinateUnit {
            public static let metric: Metric = .utf32
        }

        public enum Character: PositionCoordinateUnit {
            public static let metric: Metric = .character
        }
    }

    /// One-based logical line and code-unit column.
    struct Coordinate<Unit: PositionCoordinateUnit>: Codable, Sendable, Hashable, Comparable {
        public let line: Int
        public let column: Int

        public init(line: Int, column: Int) throws {
            guard line > 0 else { throw PositionError.invalidLine(line) }
            guard column > 0 else { throw PositionError.invalidColumn(column) }
            self.line = line
            self.column = column
        }

        private enum CodingKeys: String, CodingKey { case line, column }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let line = try container.decode(Int.self, forKey: .line)
            let column = try container.decode(Int.self, forKey: .column)
            do {
                try self.init(line: line, column: column)
            } catch {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: decoder.codingPath, debugDescription: "Coordinate must have positive line and column", underlyingError: error)
                )
            }
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.line == rhs.line ? lhs.column < rhs.column : lhs.line < rhs.line
        }
    }

    /// Zero-based absolute code-unit offset into an exact source snapshot.
    struct Offset<Unit: PositionCoordinateUnit>: Codable, Sendable, Hashable, Comparable {
        public let offset: Int

        public init(_ offset: Int) throws {
            guard offset >= 0 else { throw TextCoordinateError.invalidOffset(offset) }
            self.offset = offset
        }

        private enum CodingKeys: String, CodingKey { case offset }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let value = try container.decode(Int.self, forKey: .offset)
            do {
                try self.init(value)
            } catch {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: decoder.codingPath, debugDescription: "Offset must be nonnegative", underlyingError: error)
                )
            }
        }

        public static func < (lhs: Self, rhs: Self) -> Bool { lhs.offset < rhs.offset }
    }

    /// Half-open, source-order coordinate range [start, end).
    struct CoordinateRange<Unit: PositionCoordinateUnit>: Codable, Sendable, Hashable {
        public let start: Coordinate<Unit>
        public let end: Coordinate<Unit>

        public init(start: Coordinate<Unit>, end: Coordinate<Unit>) throws {
            guard start <= end else { throw TextCoordinateError.reversedRange }
            self.start = start
            self.end = end
        }

        private enum CodingKeys: String, CodingKey { case start, end }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let start = try container.decode(Coordinate<Unit>.self, forKey: .start)
            let end = try container.decode(Coordinate<Unit>.self, forKey: .end)
            do {
                try self.init(start: start, end: end)
            } catch {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: decoder.codingPath, debugDescription: "Range end precedes start", underlyingError: error)
                )
            }
        }
    }
}

public enum TextCoordinateError: Error, Sendable, Equatable {
    case invalidLine(Int)
    case invalidColumn(Int)
    case invalidOffset(Int)
    case unalignedBoundary
    case reversedRange
}
