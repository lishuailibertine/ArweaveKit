//
//  File.swift
//  
//
//  Created by li shuai on 2022/1/21.
//

import Foundation

public struct ChainInfo: Codable{
    public let network: String
    public let version: Int
    public let release: Int
    public let height: Int
    public let current: String
    public let blocks: Int
    public let peers: Int
    public let queue_length: Int
    public let node_state_latency: Int
}
