public extension LineRange {
    @inlinable
    func intersection(
        _ other: LineRange
    ) -> LineRange? {
        let lowerBound = max(
            start,
            other.start
        )
        let upperBound = min(
            end,
            other.end
        )

        guard lowerBound <= upperBound else {
            return nil
        }

        return LineRange(
            uncheckedStart: lowerBound,
            uncheckedEnd: upperBound
        )
    }

    @inlinable
    func contains(
        _ other: LineRange
    ) -> Bool {
        start <= other.start
            && end >= other.end
    }

    @inlinable
    func expanded(
        by lineCount: UInt,
        within bounds: LineRange
    ) -> LineRange? {
        guard let bounded = intersection(
            bounds
        ) else {
            return nil
        }

        let amount = Int(
            clamping: lineCount
        )
        let lowerDistance = bounded.start - bounds.start
        let upperDistance = bounds.end - bounded.end

        return LineRange(
            uncheckedStart: bounded.start - min(
                amount,
                lowerDistance
            ),
            uncheckedEnd: bounded.end + min(
                amount,
                upperDistance
            )
        )
    }

    @inlinable
    func overlaps(
        _ other: LineRange
    ) -> Bool {
        intersection(other) != nil
    }

    @inlinable
    func gap(
        to other: LineRange
    ) -> UInt {
        if overlaps(other) {
            return 0
        }

        if end < other.start {
            return UInt(
                other.start - end - 1
            )
        }

        return UInt(
            start - other.end - 1
        )
    }

    @inlinable
    func union(
        _ other: LineRange,
        maximumGap: UInt = 0
    ) -> LineRange? {
        guard gap(
            to: other
        ) <= maximumGap else {
            return nil
        }

        return LineRange(
            uncheckedStart: min(
                start,
                other.start
            ),
            uncheckedEnd: max(
                end,
                other.end
            )
        )
    }
}

public extension Sequence where Element == LineRange {
    func coalesced(
        maximumGap: UInt = 0
    ) -> [LineRange] {
        let sortedRanges = sorted { lhs, rhs in
            if lhs.start != rhs.start {
                return lhs.start < rhs.start
            }

            return lhs.end < rhs.end
        }

        guard var current = sortedRanges.first else {
            return []
        }

        var result: [LineRange] = []

        for range in sortedRanges.dropFirst() {
            if let merged = current.union(
                range,
                maximumGap: maximumGap
            ) {
                current = merged
                continue
            }

            result.append(current)
            current = range
        }

        result.append(current)
        return result
    }
}
