public extension LineColumnTracker {
    /// Backwards compatibility.
    @available(*, deprecated, renamed: "currentPosition(file:invocation:)")
    @inlinable
    func currentLocation(
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> Position {
        currentPosition(
            file: file,
            invocation: invocation
        )
    }

    /// Backwards compatibility.
    @available(*, deprecated, renamed: "lastConsumedPosition(file:invocation:)")
    @inlinable
    func lastConsumedLocation(
        file: String? = nil,
        invocation: InvocationCallSite? = nil
    ) -> Position {
        lastConsumedPosition(
            file: file,
            invocation: invocation
        )
    }
}
