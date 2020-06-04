//
//  EnemyNode.swift
//  spaceshooter
//
//  Created by iMac on 6/2/20.
//  Copyright © 2020 Lord Nibbler. All rights reserved.
//

import SpriteKit

class EnemyNode: SKSpriteNode {
    var type: EnemyType
    var lastFireTime: Double = 0
    var shields: Int
    
    init(type: EnemyType, startPosition: CGPoint, xOffset: CGFloat, moveStraight: Bool) {
        self.type = type
        shields = type.shields
        
        // create main SpriteNode using current sprite
        let texture = SKTexture(imageNamed: type.name)
        super.init(texture: texture, color: .white, size: texture.size())
        
        physicsBody = SKPhysicsBody(texture: texture, size: texture.size())
        
        // mark it as an enemy
        physicsBody?.categoryBitMask = CollisionType.enemy.rawValue
        
        // bounce off player or player's weapon
        physicsBody?.collisionBitMask = CollisionType.player.rawValue | CollisionType.playerWeapon.rawValue
        
        // tell us about collisions of this type
        physicsBody?.contactTestBitMask = CollisionType.player.rawValue | CollisionType.playerWeapon.rawValue
        
        name = "enemy"
        position = CGPoint(x: startPosition.x + xOffset, y: startPosition.y)
        
        configureMovement(moveStraight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("LOL NO")
    }
    
    func configureMovement(_ moveStraight: Bool) {
        let path = UIBezierPath()
        
        // start with 0,0 x and y coords
        path.move(to: .zero)
        
        if moveStraight {
            // move way off screen to left
            path.addLine(to: CGPoint(x: -10_000, y: 0))
        } else {
            // use curve using control points
            // entirely arbitrary values here to make it look nice!
            path.addCurve(
                to: CGPoint(x: -3_500, y: 0),
                controlPoint1: CGPoint(x: 0, y: -position.y * 4),
                controlPoint2: CGPoint(x: -1_000, y: -position.y)
            )
        }
        
        // always face forwards on path
        let movement = SKAction.follow(path.cgPath, asOffset: true, orientToPath: true, speed: type.speed)
        
        // when it gets to left edge, destroy it
        let sequence = SKAction.sequence([movement, .removeFromParent()])
        run(sequence)
    }
    
    func fire() {
        let weaponType = "\(type.name)Weapon"
        let weapon = SKSpriteNode(imageNamed: weaponType)
        weapon.name = "enemyWeapon"
        weapon.position = self.position
        weapon.zRotation = self.zRotation
        
        // add weapon to parent of spaceship, not spaceship itself
        parent?.addChild(weapon)
        
        // faster collision detection than a texture
        weapon.physicsBody = SKPhysicsBody(rectangleOf: weapon.size)
        weapon.physicsBody?.categoryBitMask = CollisionType.enemyWeapon.rawValue
        weapon.physicsBody?.collisionBitMask = CollisionType.player.rawValue
        weapon.physicsBody?.contactTestBitMask = CollisionType.player.rawValue
        
        // density computed by size of the object; by default weapons will fire and move at different speeds
        weapon.physicsBody?.mass = 0.001
        
        // push the laser in direction of enemy with an impulse
        let speed: CGFloat = 1
        
        // rotation of offset by 90º, spritekit 0 is pointing to the right
        // assets point up; half of pi radians == 90º
        let adjustedRotation = zRotation + (CGFloat.pi / 2)
        
        // fundamental math formula for x/y velocity based on angle
        let dx = speed * cos(adjustedRotation)
        let dy = speed * sin(adjustedRotation)
        
        // push it in that direction by that amount
        weapon.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
    }
}
