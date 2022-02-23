import Foundation
import JOSESwift

public struct Arweave {
    public var baseUrl: URL = URL(string: "https://arweave.net")!
    public static let shared = Arweave()
    private init() {}
    func request(for route: Route) -> Request {
        return Request(route: route)
    }
}

enum Route {
    case txAnchor
    case chainInfo
    case transaction(id: TransactionId)
    case transactionData(id: TransactionId)
    case transactionStatus(id: TransactionId)
    case lastTransactionId(walletAddress: ArweaveAddress)
    case walletBalance(walletAddress: ArweaveAddress)
    case reward(ArweaveTransaction.PriceRequest)
    case commit(ArweaveTransaction)
}

extension Arweave {
    
    struct Request {
        
        var route: Route
        
        var path: String {
            switch route {
            case .txAnchor:
                return "/tx_anchor"
            case .chainInfo:
                return "/info"
            case let .transaction(id):
                return "/tx/\(id)"
            case let .transactionData(id):
                return "/tx/\(id)/data"
            case let .transactionStatus(id):
                return "/tx/\(id)/status"
            case let .lastTransactionId(walletAddress):
                return "/wallet/\(walletAddress)/last_tx"
            case let .walletBalance(walletAddress):
                return "/wallet/\(walletAddress)/balance"
            case let .reward(request):
                var path = "/price/\(String(request.bytes))"
                if let target = request.target {
                    path.append("/\(target.address)")
                }
                return path
            case .commit:
                return "/tx"
            }
        }
        
        var url: URL {
            Arweave.shared.baseUrl.appendingPathComponent(path)
        }
        
        var method: String {
            if case Route.commit = route {
                return "post"
            } else {
                return "get"
            }
        }
        
        var body: Data? {
            if case let Route.commit(transaction) = route {
                return try? JSONEncoder().encode(transaction)
            } else {
                return nil
            }
        }
        
        var headers: [String: String]? {
            ["Content-type": "application/json"]
        }
    }
}
