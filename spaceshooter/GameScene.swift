//
//  GameScene.swift
//  spaceshooter
//
//  Created by iMac on 6/2/20.
//  Copyright © 2020 Lord Nibbler. All rights reserved.
//

import SpriteKit
import CoreMotion

// distinct types of collisions between nodes
enum CollisionType: UInt32 {
    case player = 1
    case playerWeapon = 2
    case enemy = 4
    case enemyWeapon = 8
}


// SKPhysicsContactDelegate - want to be told when collisions happen
class GameScene: SKScene, SKPhysicsContactDelegate {
    // for accelerometer input
    let motionManager = CMMotionManager()
    
    let player = SKSpriteNode(imageNamed: "player")
    
    let waves = Bundle.main.decode([Wave].self, from: "waves.json")
    let enemyTypes = Bundle.main.decode([EnemyType].self, from: "enemy-types.json")
    
    var isPlayerAlive = true
    var levelNumber = 0
    var waveNumber = 0
    var playerShields = 10
    
    // figure out Y coords to create enemies with (768 height screen, only using 640 of that)
    let positions = Array(stride(from: -320, through: 320, by: 80))
    
    override func didMove(to view: SKView) {
        // because space
        physicsWorld.gravity = .zero
        
        // tell me when collisions happen
        physicsWorld.contactDelegate = self
        
        if let particles = SKEmitterNode(fileNamed: "starfield") {
            particles.position = CGPoint(x: 1080, y: 0)
            
            // fast forward emitter 60s to avoid empty screen on launch
            particles.advanceSimulationTime(60)
            
            // behind things in the game
            particles.zPosition = -1
            addChild(particles)
            
        }
        
        // add player node to scene
        player.name = "player"
        player.position.x = frame.minX + 75
        player.zPosition = 1 // above other elements
        addChild(player)
        
        // give the player a physics body
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        
        // what kind of thing this is in physics word
        player.physicsBody?.categoryBitMask = CollisionType.player.rawValue
        
        // what it collides with in physics space
        // single pipe == bitwise OR (add them together); 4 + 8 => 12
        player.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        
        // what things, when they collide, do we want to be told about?
        // useful for powerups!
        player.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        
        // don't be pushed around by gravity
        player.physicsBody?.isDynamic = false
        
        // start reading accelerometer
        motionManager.startAccelerometerUpdates()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // called before GameScene is drawn every time (60-120 times per second)
        
        if let accelerometerData = motionManager.accelerometerData {
            // modify position of player based on this (using X accelerometer data)
            // multiply value by large number to make effect of tilt more pronounced
            player.position.y += CGFloat(accelerometerData.acceleration.x * 50)
            
            // if they try to go off screen, stop it
            if player.position.y < frame.minY {
                player.position.y = frame.minY
            } else if player.position.y > frame.maxY {
                player.position.y = frame.maxY
            }
        }
        
        for child in children {
            // at least half way onto the screen
            if child.frame.maxX < 0 {
                // not visible on gamescene somewhere
                if !frame.intersects(child.frame) {
                    // remove it immediately
                    child.removeFromParent()
                }
            }
        }
        
        // array of all enemy nodes in current game
        let activeEnemies = children.compactMap { $0 as? EnemyNode }
        if activeEnemies.isEmpty {
            // create wave when no more enemies are visible on screen
            createWave()
        }
        
        // go through all enemires we have
        for enemy in activeEnemies {
            // make sure it is visible on screen
            guard frame.intersects(enemy.frame) else { continue }
            
            // has 1 second passed since they fired?
            if enemy.lastFireTime + 1 < currentTime {
                // fired now
                enemy.lastFireTime = currentTime
                
                // 1 in 7 chance to fire each time
                if Int.random(in: 0...6) == 0 {
                    enemy.fire()
                }
            }
        }
    }
    
    func createWave() {
        // is the player still alive?
        guard isPlayerAlive else { return }
        
        // are we at the limit of our waves?
        // next level, reset waves
        if waveNumber == waves.count {
            levelNumber += 1
            waveNumber = 0
        }
        
        // you're on level <whatever>, here are the enemies to create for the wave
        let currentWave = waves[waveNumber]
        waveNumber += 1
        
        // make a random enemy type between 0 and some other acceptable value for wave
        let maximumEnemyType = min(enemyTypes.count, levelNumber + 1)
        let enemyType = Int.random(in: 0..<maximumEnemyType)
        
        // how far to place subsequent enemies behind each other
        let enemyOffsetX: CGFloat = 100
        
        // position they start when first name with no enemy offset (just off the screen, ~512)
        let enemyStartX = 600
        
        // if we are currently out of enemies in the wave, it is a random wave (make them whatever want to)
        if currentWave.enemies.isEmpty {
            // shuffle up all positions and position them around our space
            // mix up and enumerate them
            for (index, position) in positions.shuffled().enumerated() {
                let enemy = EnemyNode(
                    type: enemyTypes[enemyType],
                    startPosition: CGPoint(x: enemyStartX, y: position),
                    xOffset: enemyOffsetX * CGFloat(index * 3),  // arbitrary; push back enemy offset to be bigger
                    moveStraight: true
                )
                addChild(enemy)
            }
        } else {
            // we have enemies, not random wave
            for enemy in currentWave.enemies {
                let node = EnemyNode(
                    type: enemyTypes[enemyType],
                    startPosition: CGPoint(x: enemyStartX, y: positions[enemy.position]), // off screen slightly
                    xOffset: enemyOffsetX * enemy.xOffset, // defined in json, some number of pixel offset
                    moveStraight: enemy.moveStraight // defined in json, how should they move?
                )
                addChild(node)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPlayerAlive else { return }
        
        let shot = SKSpriteNode(imageNamed: "playerWeapon")
        shot.name = "playerWeapon"
        shot.position = player.position
        shot.physicsBody = SKPhysicsBody(rectangleOf: shot.size)
        shot.physicsBody?.categoryBitMask = CollisionType.playerWeapon.rawValue
        shot.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        shot.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        addChild(shot)
        
        let movement = SKAction.move(
            to: CGPoint(x: 1900, y: shot.position.y),
            duration: 5
        )
        let sequence = SKAction.sequence([movement, .removeFromParent()])
        shot.run(sequence)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // when a contact happens what do you want to do
        // what nodes were impacted by this?
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        // which is our player, weapon, enemy, etc?
        // make sure that enemy first, then enemyWeapon, then player, then playerWeapon
        let sortedNodes = [nodeA, nodeB].sorted { $0.name ?? ""  < $1.name ?? "" }
        
        // know for sure if player is in the sortedNodes, it will be nodeB
        let firstNode = sortedNodes[0]
        let secondNode = sortedNodes[1]
        
        // can never be firstNode due to sorting
        if secondNode.name == "player" {
            // if enemy or enemyWeapon collides w/ player
            
            // first make sure player is still alive
            guard isPlayerAlive else { return }
            
            // if they are alive, destroy the other node (enemy or enemyWeapon)
            if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                // show explosion at enemy position
                explosion.position = firstNode.position
                addChild(explosion)
            }
            playerShields -= 1
            
            if playerShields == 0 {
                 gameOver()
                
                // dead, remove player, game is over
                secondNode.removeFromParent()
            }
            
            //
            firstNode.removeFromParent()
        } else if let enemy = firstNode as? EnemyNode {
            // if firstNode is enemy, enemy is hit by player
            // typecast to make sure we have EnemyNode type rather than SKNode
            enemy.shields -= 1
            
            // if enemy is dead, explode, remove from scene
            if enemy.shields == 0 {
                if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                    explosion.position = enemy.position
                    addChild(explosion)
                }
                enemy.removeFromParent()
            }
            
            // second explosion based on where weapon hit
            if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                explosion.position = enemy.position
                addChild(explosion)
            }
            secondNode.removeFromParent()
        } else {
            // two other things collided; the player weapon collides with enemy weapon
            if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                explosion.position = secondNode.position
                addChild(explosion)
            }
            firstNode.removeFromParent()
            secondNode.removeFromParent()
        }
    }
    
    func gameOver() {
        isPlayerAlive = false
        
        if let explosion = SKEmitterNode(fileNamed: "Explosion") {
            explosion.position = self.player.position
            addChild(explosion)
        }

        let gameOver = SKSpriteNode(imageNamed: "gameOver")
        addChild(gameOver)
    }
}
