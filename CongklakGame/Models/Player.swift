//
//  Player.swift
//  CongklakGame
//
//  Created by irwan on 29/01/26.
//

import Foundation

enum Player: Int, CaseIterable {
    case one = 0
    case two = 1
    

    var opponent: Player {
        switch self {
        case .one: return .two
        case .two: return .one
        }
    }
    

    var displayName: String {
        switch self {
        case .one: return "Player 1"
        case .two: return "Player 2"
        }
    }
}
