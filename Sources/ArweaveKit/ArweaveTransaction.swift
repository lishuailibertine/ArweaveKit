import Foundation
import CryptoKit
import UIKit
import PromiseKit

public typealias TransactionId = String
public typealias Base64EncodedString = String

public extension ArweaveTransaction {

    struct PriceRequest {
        
        public init(bytes: Int = 0, target: ArweaveAddress? = nil) {
            self.bytes = bytes
            self.target = target
        }
        
        public var bytes: Int = 0
        public var target: ArweaveAddress?
    }

    struct Tag: Codable {
        public let name: String
        public let value: String

        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }
    }
}

public struct ArweaveTransaction: Codable {
    public var id: TransactionId = ""
    public var last_tx: TransactionId = ""
    public var owner: String = ""
    public var tags = [Tag]()
    public var target: String = ""
    public var quantity: String = "0"
    public var data: String = ""
    public var reward: String = ""
    public var signature: String = ""

    private enum CodingKeys: String, CodingKey {
        case id, last_tx, owner, tags, target, quantity, data, reward, signature
    }

    public var priceRequest: PriceRequest {
        PriceRequest(bytes: rawData.count, target: ArweaveAddress(address: target))
    }

    public var rawData = Data()
}

public extension ArweaveTransaction {
    init(data: Data) {
        self.rawData = data
    }

    init(amount: Amount, target: ArweaveAddress) {
        self.quantity = String(describing: amount)
        self.target = target.address
    }
    
    func build(ownerModulus:String)-> Promise<ArweaveTransaction>{
        return Promise { seal in
            var tx = self
            firstly {
               return ArweaveTransaction.anchor()
            }.then { txAnchor -> Promise<Amount> in
                tx.last_tx = txAnchor
                tx.data = rawData.base64URLEncodedString()
                return ArweaveTransaction.price(for: priceRequest)
            }.done({ priceAmount in
                tx.reward = String(describing: priceAmount)
                tx.owner = ownerModulus
                seal.fulfill(tx)
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    func commit() -> Promise<Data>{
        return Promise { seal in
            guard !signature.isEmpty else {
                seal.reject(ArweaveApiError.otherError(errorMessage: "Missing signature on transaction."))
                return
            }
            let commit = Arweave.shared.request(for: .commit(self))
            HttpClient.request(commit).done { response in
                seal.fulfill(response.data)
            }.catch { _ in
                seal.reject(ArweaveApiError.commitError)
            }
        }
    }

    private func signatureBody() -> Data {
        return [
            Data(base64URLEncoded: owner),
            Data(base64URLEncoded: target),
            rawData,
            quantity.data(using: .utf8),
            reward.data(using: .utf8),
            Data(base64URLEncoded: last_tx),
            tags.combined.data(using: .utf8)
        ]
        .compactMap { $0 }
        .combined
    }
}

public extension ArweaveTransaction {
    static func find(_ txId: TransactionId) -> Promise<ArweaveTransaction>{
        return Promise { seal in
            let findEndpoint = Arweave.shared.request(for: .transaction(id: txId))
            HttpClient.request(findEndpoint).done{ response in
                do {
                    let transaction = try JSONDecoder().decode(ArweaveTransaction.self, from: response.data)
                    seal.fulfill(transaction)
                } catch  _ {
                    seal.reject(ArweaveApiError.findError)
                }
            }.catch { _ in
                seal.reject(ArweaveApiError.findError)
            }
        }
    }
    static func data(for txId: TransactionId) -> Promise<Base64EncodedString>{
        return Promise { seal in
            let target = Arweave.shared.request(for: .transactionData(id: txId))
            HttpClient.request(target).done { response in
                seal.fulfill(String(decoding: response.data, as: UTF8.self))
            }.catch { _ in
                seal.reject(ArweaveApiError.getTransactionDataError)
            }
        }
    }

    static func status(of txId: TransactionId) -> Promise<ArweaveTransaction.Status>{
        return Promise { seal in
            let target = Arweave.shared.request(for: .transactionStatus(id: txId))
            HttpClient.request(target).done { response in
                do {
                    var status: ArweaveTransaction.Status
                    if response.statusCode == 200 {
                        let data = try JSONDecoder().decode(ArweaveTransaction.Status.Data.self, from: response.data)
                        status = .accepted(data: data)
                    } else {
                        status = ArweaveTransaction.Status(rawValue: .status(response.statusCode))!
                    }
                    seal.fulfill(status)
                } catch _ {
                    seal.reject(ArweaveApiError.transactionStatusError)
                }
            }.catch { _ in
                seal.reject(ArweaveApiError.transactionStatusError)
            }
        }
    }

    static func price(for request: ArweaveTransaction.PriceRequest)-> Promise<Amount>{
        return Promise { seal in
            let target = Arweave.shared.request(for: .reward(request))
            HttpClient.request(target).done { response in
                let costString = String(decoding: response.data, as: UTF8.self)
                guard let value = Double(costString) else {
                    seal.reject(ArweaveApiError.priceError)
                    return
                }
                seal.fulfill(Amount(value: value, unit: .winston))
            }.catch { _ in
                seal.reject(ArweaveApiError.priceError)
            }
        }
    }

    static func anchor() -> Promise<String>{
        return Promise { seal in
            let target = Arweave.shared.request(for: .txAnchor)
            HttpClient.request(target).done { response in
                let anchor = String(decoding: response.data, as: UTF8.self)
                seal.fulfill(anchor)
            }.catch { _ in
                seal.reject(ArweaveApiError.anchorError)
            }
        }
    }
    static func info() -> Promise<ChainInfo>{
        return Promise { seal in
            let infoR = Arweave.shared.request(for: .chainInfo)
            HttpClient.request(infoR).done { response in
                let info = try JSONDecoder().decode(ChainInfo.self, from: response.data)
                seal.fulfill(info)
            }.catch { _ in
                seal.reject(ArweaveApiError.chainInfoError)
            }
        }
    }
}

extension Array where Element == ArweaveTransaction.Tag {
    var combined: String {
        reduce(into: "") { str, tag in
            str += tag.name
            str += tag.value
        }
    }
}
