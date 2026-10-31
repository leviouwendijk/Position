import Foundation

public extension Position {
    /// Immutable, exact-source conversion between UTF-8, UTF-16, Unicode scalar,
    /// and Swift Character coordinates. No implicit clamping or normalization.
    struct TextMap: Sendable {
        private struct Counts: Sendable {
            var utf8: Int = 0
            var utf16: Int = 0
            var utf32: Int = 0
            var character: Int = 0

            func value(_ metric: Unit.Metric) -> Int {
                switch metric {
                case .utf8: utf8
                case .utf16: utf16
                case .utf32: utf32
                case .character: character
                }
            }

            mutating func add(_ other: Counts) {
                utf8 += other.utf8
                utf16 += other.utf16
                utf32 += other.utf32
                character += other.character
            }
        }

        private struct Boundary: Sendable {
            let counts: Counts
            let characterBoundary: Bool
        }

        private struct Line: Sendable {
            let start: Counts
            let boundaries: [Boundary]
        }

        public let source: String
        private let lines: [Line]

        public init(source: String) {
            self.source = source
            let bytes = Array(source.utf8)
            var lines: [Line] = []
            var totals = Counts()
            var cursor = 0

            while true {
                let start = cursor
                while cursor < bytes.count && bytes[cursor] != 10 && bytes[cursor] != 13 {
                    cursor += 1
                }
                let content = String(decoding: bytes[start..<cursor], as: UTF8.self)
                let boundaries = Self.boundaries(for: content)
                lines.append(Line(start: totals, boundaries: boundaries))
                totals.add(boundaries.last!.counts)

                guard cursor < bytes.count else { break }
                let crlf = bytes[cursor] == 13 && cursor + 1 < bytes.count && bytes[cursor + 1] == 10
                let width = crlf ? 2 : 1
                cursor += width
                totals.utf8 += width
                totals.utf16 += width
                totals.utf32 += width
                totals.character += 1
            }
            self.lines = lines
        }

        private static func boundaries(for content: String) -> [Boundary] {
            var counts = Counts()
            var result: [Boundary] = [.init(counts: counts, characterBoundary: true)]
            for character in content {
                let scalars = Array(String(character).unicodeScalars)
                for (index, scalar) in scalars.enumerated() {
                    if #available(macOS 10.15, *) {
                        counts.utf8 += scalar.utf8.count
                    } else {
                        counts.utf8 += String(scalar).utf8.count
                    }
                    counts.utf16 += scalar.utf16.count
                    counts.utf32 += 1
                    let isEnd = index == scalars.count - 1
                    if isEnd { counts.character += 1 }
                    result.append(.init(counts: counts, characterBoundary: isEnd))
                }
            }
            return result
        }

        private func boundary<U: PositionCoordinateUnit>(
            in line: Line,
            at local: Int,
            as unit: U.Type
        ) -> Boundary? {
            var lower = 0
            var upper = line.boundaries.count

            while lower < upper {
                let middle = lower + (upper - lower) / 2
                if line.boundaries[middle].counts.value(U.metric) < local {
                    lower = middle + 1
                } else {
                    upper = middle
                }
            }

            guard lower < line.boundaries.count else {
                return nil
            }
            let candidate = line.boundaries[lower]
            guard candidate.counts.value(U.metric) == local,
                  U.metric != .character || candidate.characterBoundary else {
                return nil
            }
            return candidate
        }

        private func boundary<U: PositionCoordinateUnit>(
            at coordinate: Coordinate<U>
        ) throws -> (Line, Boundary) {
            guard lines.indices.contains(coordinate.line - 1) else {
                throw TextCoordinateError.invalidLine(coordinate.line)
            }
            let line = lines[coordinate.line - 1]
            guard let matched = boundary(
                in: line,
                at: coordinate.column - 1,
                as: U.self
            ) else {
                throw TextCoordinateError.invalidColumn(coordinate.column)
            }
            return (line, matched)
        }

        private func boundary<U: PositionCoordinateUnit>(
            at offset: Offset<U>
        ) throws -> (Int, Line, Boundary) {
            var lower = 0
            var upper = lines.count

            while lower < upper {
                let middle = lower + (upper - lower) / 2
                if lines[middle].start.value(U.metric) <= offset.offset {
                    lower = middle + 1
                } else {
                    upper = middle
                }
            }

            guard lower > 0 else {
                throw TextCoordinateError.invalidOffset(offset.offset)
            }
            let index = lower - 1
            let line = lines[index]
            let local = offset.offset - line.start.value(U.metric)
            guard let matched = boundary(in: line, at: local, as: U.self) else {
                throw TextCoordinateError.invalidOffset(offset.offset)
            }
            return (index + 1, line, matched)
        }

        public func offset<U: PositionCoordinateUnit>(at coordinate: Coordinate<U>) throws -> Offset<U> {
            let (line, boundary) = try boundary(at: coordinate)
            return try .init(line.start.value(U.metric) + boundary.counts.value(U.metric))
        }

        public func coordinate<U: PositionCoordinateUnit>(at offset: Offset<U>) throws -> Coordinate<U> {
            let (number, _, boundary) = try boundary(at: offset)
            return try .init(line: number, column: boundary.counts.value(U.metric) + 1)
        }

        public func convert<From: PositionCoordinateUnit, To: PositionCoordinateUnit>(
            _ coordinate: Coordinate<From>,
            to: To.Type
        ) throws -> Coordinate<To> {
            let (_, boundary) = try boundary(at: coordinate)
            guard To.metric != .character || boundary.characterBoundary else {
                throw TextCoordinateError.unalignedBoundary
            }
            return try .init(line: coordinate.line, column: boundary.counts.value(To.metric) + 1)
        }

        public func convert<From: PositionCoordinateUnit, To: PositionCoordinateUnit>(
            _ offset: Offset<From>,
            to: To.Type
        ) throws -> Offset<To> {
            let (_, line, boundary) = try boundary(at: offset)
            guard To.metric != .character || boundary.characterBoundary else {
                throw TextCoordinateError.unalignedBoundary
            }
            return try .init(line.start.value(To.metric) + boundary.counts.value(To.metric))
        }

        public func convert<From: PositionCoordinateUnit, To: PositionCoordinateUnit>(
            _ range: CoordinateRange<From>,
            to: To.Type
        ) throws -> CoordinateRange<To> {
            try .init(
                start: convert(range.start, to: To.self),
                end: convert(range.end, to: To.self)
            )
        }

        public func utf8Offset(at coordinate: Coordinate<Unit.UTF16>) throws -> Offset<Unit.UTF8> {
            let (line, boundary) = try boundary(at: coordinate)
            return try .init(line.start.utf8 + boundary.counts.utf8)
        }

        public func utf8Range(of range: CoordinateRange<Unit.UTF16>) throws -> Range<Int> {
            let start = try utf8Offset(at: range.start).offset
            let end = try utf8Offset(at: range.end).offset
            guard start <= end else { throw TextCoordinateError.reversedRange }
            return start..<end
        }
    }
}
