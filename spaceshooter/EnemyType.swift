//
//  enemyType.swift
//  spaceshooter
//
//  Created by iMac on 6/2/20.
//  Copyright © 2020 Lord Nibbler. All rights reserved.
//

import SpriteKit

struct EnemyType: Codable {
    let name: String
    let shields: Int
    let speed: CGFloat // speed in spritekit must be CGFloat
    let powerUpChance: Int
}
