import Foundation
import CryptoKit

extension Digest {
   public var bytes: [UInt8] { Array(makeIterator()) }
   public var data: Data { Data(bytes) }
}

extension String {
   public var base64URLEncoded: String {
        Data(utf8).base64URLEncodedString()
   }
}

extension Array where Element == Data {
    public var combined: Data {
       reduce(.init(), +)
    }
}
