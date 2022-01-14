//
//  ExchangeResponse.swift
//  ExchangeRate
//
//  Created by Jae Kyeong Ko on 2022/01/11.
//

import Foundation

struct ExchangeResponse: Decodable {
    let timestamp: Int
    let quotes: Quotes
}

struct Quotes: Decodable {
    let usdphp: Double
    let usdkrw: Double
    let usdjpy: Double
    
    enum CodingKeys: String, CodingKey {
        case usdphp = "USDPHP"
        case usdkrw = "USDKRW"
        case usdjpy = "USDJPY"
    }
}
