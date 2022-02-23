import XCTest
import CryptoKit
@testable import ArweaveKit

final class WalletTests: XCTestCase {

    static let walletAddress = ArweaveAddress(address: "3t2aPa6RArz9ssZ-pEmPiI6rUwAy1v69wm_7Qn0uUt8")
    static var wallet: ArweaveWallet?
    
    class func initWalletFromKeyfile() {
        
        guard let keyPath = Bundle.module.url(forResource: "test-key", withExtension: "json"),
              let keyData = try? Data(contentsOf: keyPath)
        else { return }
        
        WalletTests.wallet = try? ArweaveWallet(jwkFileData: keyData)
        
        XCTAssertNotNil(WalletTests.wallet)
        XCTAssertEqual(WalletTests.walletAddress, WalletTests.wallet?.address)
    }
    
    override class func setUp() {
        super.setUp()
        WalletTests.initWalletFromKeyfile()
    }
    
    func testCheckWalletBalance() throws {
        let expection = expectation(description: "testCheckWalletBalance")
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                let balance = try WalletTests.wallet?.balance().wait()
//                expection.fulfill(balance)
//            } catch ( _) {
//                expection.fulfill()
//            }
//        }
        waitForExpectations(timeout: 10)
    }
    
//    func testCheckWalletBalance_UsingCustomHost() async throws {
//        Arweave.baseUrl = URL(string: "https://arweave.net:443")!
//        let balance = try await WalletTests.wallet?.balance()
//        XCTAssertNotNil(balance?.value)
//    }
//
//    func testFetchLastTransactionId() async throws {
//        let lastTxId = try await WalletTests.wallet?.lastTransactionId()
//        XCTAssertNotNil(lastTxId)
//    }

    func testSignMessage() throws {
        let msg = try XCTUnwrap("Arweave".data(using: .utf8))
        let wallet = try XCTUnwrap(WalletTests.wallet)
        let signedData = try wallet.sign(msg)

        let hash = SHA256.hash(data: signedData).data.base64URLEncodedString()
        XCTAssertNotNil(hash)
    }

    func testWinstonToARConversion() {
        var transferAmount = Amount(value: 1, unit: .AR)
        let amtInWinston = transferAmount.converted(to: .winston)
        XCTAssertEqual(amtInWinston.value, 1000000000000, accuracy: 0e-12)

        transferAmount = Amount(value: 2, unit: .winston)
        let amtInAR = transferAmount.converted(to: .AR)
        XCTAssertEqual(amtInAR.value, 0.000000000002, accuracy: 0e-12)
    }
}
