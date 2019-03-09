//
//  GameScene.swift
//  MarlbeMaze
//
//  Created by Simon Italia on 3/8/19.
//  Copyright © 2019 SDI Group Inc. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var motionManager: CMMotionManager!
    var player: SKSpriteNode!
    var lastTouchPosition: CGPoint?
    
    //Score properties
    var scoreLabel: SKLabelNode!
    
    var playerScore = 0 {
        didSet {
            scoreLabel.text = "Score: \(playerScore)"
        }
    }
    
    var isGameOver = false
    
    override func didMove(to view: SKView) {
        
        //Set Scene as delegate of itself
        physicsWorld.contactDelegate = self
        
        //Set scene background
        let background = SKSpriteNode(imageNamed: "background.jpg")
        background.name = "background"
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        addChild(scoreLabel)
        
        //Turn off physicsWorld gravity
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        //Load level
        loadLevel()
        
        //Load player (note this method follows load level so player doesn't appear below any of the loadLevel nodes)
        createPlayer()
        
        //Configure motion tracking
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        
    }

    //Create maze level
    func loadLevel() {
        if let levelPath = Bundle.main.path(forResource: "level1", ofType: "txt") {
            if let levelString = try? String(contentsOfFile: levelPath) {
                let lines = levelString.components(separatedBy: "\n")
                
                for (row, line) in lines.reversed().enumerated() {
                    for (column, letter) in line.enumerated() {
                        let position = CGPoint (x: (64 * column) + 32, y: (64 * row) + 32)
                        
                        if letter == "x" {
                            //load wall
                            let node = SKSpriteNode(imageNamed: "block")
                            node.name = "wall"
                            node.position = position
                            
                            node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                            node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
                            node.physicsBody?.isDynamic = false
                            addChild(node)
  
                        } else if letter == "v" {
                            //load vortex
                            let node = SKSpriteNode(imageNamed: "vortex")
                            node.name = "vortex"
                            node.position = position
                            node.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat.pi, duration: 1)))
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                            node.physicsBody?.isDynamic = false
                            
                            node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
                            node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                            node.physicsBody?.collisionBitMask = 0
                            addChild(node)
                        
                        } else if letter == "s" {
                            //load star
                            let node = SKSpriteNode(imageNamed: "star")
                            node.name = "star"
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                            node.physicsBody?.isDynamic = false

                            node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
                            node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                            node.physicsBody?.collisionBitMask = 0
                            node.position = position
                            addChild(node)
                        
                        } else if letter == "f" {
                            //load finish
                            let node = SKSpriteNode(imageNamed: "finish")
                            node.name = "finish"
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                            node.physicsBody?.isDynamic = false
                            
                            node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
                            node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                            node.physicsBody?.collisionBitMask = 0
                            node.position = position
                            addChild(node)
                        }
                    }
                }
            }
        }
    } //End loadLevel() method
    
    //Create player
    func createPlayer() {
        player = SKSpriteNode(imageNamed: "player")
        player.position = CGPoint(x: 96, y: 672)
        
        //Add PhysicsBody properties
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue |
        CollisionTypes.vortex.rawValue |
        CollisionTypes.finish.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        
        addChild(player)
    }
    
    //Detect where player first touches the screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            lastTouchPosition = location
        }
        
    }
    
    //MARK: - Following code is to allow screen touches for testing purposes
    
    //Detect where player moves across the screen
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            lastTouchPosition = location
            
        }
    }
    
    //Detect when player stops touching screen
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    //Detect when screen touches are interrupted
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    //Detect changes per frame drawn to screen
    override func update(_ currentTime: TimeInterval) {
        
        //Ensure game isn't over before executing
        guard isGameOver == false else {return}
        
        //Wrap execution within a compiler instructions:
        //If simulatro
        #if targetEnvironment(simulator)
            //Detect differences in player touches for each frame drawn
            if let currentTouch = lastTouchPosition {
                let diff = CGPoint(x: currentTouch.x - player.position.x, y: currentTouch.y - player.position.y)
                physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
            }
        
        //If actual device
        #else
            //Poll motionManager to get latest tilt data and update player
            if let accelerometerData = motionManager.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelorometerData.acceleration.y * -50, dy: acceleromoterData.accelleration.x * 50)
        }
        #endif
    } //End update()
    
    //Detect contacts and collisions between nodes and player node
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node == player {
            playerCollided(with: contact.bodyB.node!)
            
        } else if contact.bodyB.node == player {
            playerCollided(with: contact.bodyA.node!)
        }
    }
    
    func playerCollided(with node: SKNode) {
        
        if node.name == "vortex" {
            player.physicsBody?.isDynamic = false
            playerScore -= 1
            isGameOver = true
            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move, scale, remove])
            
            player.run(sequence) { [unowned self] in
                self.createPlayer()
                self.isGameOver = false
            }
        
        } else if node.name == "star" {
            node.removeFromParent()
            playerScore += 1
            
        } else if node.name == "finish" {
            //Load next level
        }
    }
    
}

