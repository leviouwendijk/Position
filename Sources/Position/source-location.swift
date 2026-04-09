// import Foundation

@available(*, deprecated, renamed: "Position")
public typealias SourceLocation = Position

// public struct SourceLocation: CustomStringConvertible, Codable, Sendable, Hashable {
//     public let file: String?
//     public let line: Int
//     public let column: Int
//     public let invocation: InvocationCallSite?

//     public init(
//         file: String? = nil,
//         line: Int,
//         column: Int,
//         invocation: InvocationCallSite? = nil
//     ) {
//         self.file = file
//         self.line = line
//         self.column = column
//         self.invocation = invocation
//     }

//     public var description: String {
//         let base = if let file {
//             "\(file):\(line):\(column)"
//         } else {
//             "\(line):\(column)"
//         }

//         if let invocation, !invocation.description.isEmpty {
//             return base + " " + invocation.description
//         }

//         return base
//     }
// }

// public extension Optional where Wrapped == SourceLocation {
//     var describeSuffix: String {
//         switch self {
//         case .some(let location):
//             return " at \(location)"

//         case .none:
//             return ""
//         }
//     }
// }
