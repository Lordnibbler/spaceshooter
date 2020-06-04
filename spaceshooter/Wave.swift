//
//  Wave.swift
//  spaceshooter
//
//  Created by iMac on 6/2/20.
//  Copyright © 2020 Lord Nibbler. All rights reserved.
//

import SpriteKit

struct Wave: Codable {
    struct WaveEnemy: Codable {
        let position: Int
        let xOffset: CGFloat
        let moveStraight: Bool
    }
    
    let name: String
    let enemies: [WaveEnemy]
}
