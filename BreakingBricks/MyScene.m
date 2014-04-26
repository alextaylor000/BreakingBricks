//
//  MyScene.m
//  BreakingBricks
//
//  Created by Alex Taylor on 2014-04-22.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "MyScene.h"
#import "EndScene.h"

@interface MyScene ()

// add a publicly-accesible padde so we can access it outside of the class
@property SKSpriteNode *paddle;




@end

// categories
// static = available throughout the scene class
// constant = can't change
// uint32_t = official type of the SK physics bitmask

// the numbers are BINARY NUMBERS, which is why they only flip one bit.
// they're not positional

// so 8 in binary = 1000

// that's why this isn't the best way to do things
//static const uint32_t ballCategory      = 1; //00000000000000000000000000000001
//static const uint32_t brickCategory     = 2; //00000000000000000000000000000010
//static const uint32_t paddleCategory    = 4; //00000000000000000000000000000100
//static const uint32_t edgeCategory      = 8; ////000000000000000000000000001000

// set categories using bitwise operators
static const uint32_t ballCategory      = 0x1;
static const uint32_t brickCategory     = 0x1 << 1; // set the first bit to 1, and shift it to the left
static const uint32_t paddleCategory    = 0x1 << 2;
static const uint32_t edgeCategory      = 0x1 << 3;
static const uint32_t bottomEdgeCategory = 0x1 << 4;


@implementation MyScene {
    SKAction *soundPaddleHit;
    SKAction *soundBrickHit;
}


// the contact methods are being provided by the delegate
// which was delcared in the header
- (void)didBeginContact:(SKPhysicsContact *)contact {
    
    // impossible to predict which object is bodyA
    // and which object is bodyB
    
    // create a placeholder for the "non-ball" object
    SKPhysicsBody *notTheBall;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        notTheBall = contact.bodyB;
    } else {
        notTheBall = contact.bodyA;
    }
    
    if (notTheBall.categoryBitMask == brickCategory) {
        [self runAction:soundBrickHit];
        [notTheBall.node removeFromParent];
    }
    
    if (notTheBall.categoryBitMask == paddleCategory) {
        
        [self runAction:soundPaddleHit];
    }
    
    if (notTheBall.categoryBitMask == bottomEdgeCategory) {
        EndScene *end = [EndScene sceneWithSize:self.size];
        [self.view presentScene:end transition:[SKTransition doorsCloseHorizontalWithDuration:0.5]];
        
    }
    
    
}

- (void)didEndContact:(SKPhysicsContact *)contact {
    
}

- (void)addBottomEdge:(CGSize) size {
    // the "game over" edge at the bottom
    SKNode *bottomEdge = [SKNode node]; // this acts as an invisible container so we can give it a physics body
    bottomEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(0, 1) toPoint:CGPointMake(self.size.width, 1)];
    bottomEdge.physicsBody.categoryBitMask = bottomEdgeCategory;
    
    [self addChild:bottomEdge];
    
}

- (void)addBall:(CGSize)size
{
    // create sprite
    SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"orb0000"];
    
    CGPoint myPoint = CGPointMake(size.width/2, size.height/2);
    ball.position = myPoint;
    
    // add physics body to ball
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:ball.frame.size.width/2];
    
    // reduce friction
    // describes the energy lost when objects slide against each other
    ball.physicsBody.friction = 0;
    
    // reduce linear damping
    // this applies resistance to objects moving across the screen
    
    // it does not do anything to control what happens when
    // an object bounces off something else - it will still lose energy
    ball.physicsBody.linearDamping = 0;
    
    // reduce restitution
    // restitution = bounciness; how much energy is lost when an object
    //  collides with another
    
    //  this is a percentage of how much energy is lost when collision occurs
    ball.physicsBody.restitution = 1.0;
    
    // set categories
    ball.physicsBody.categoryBitMask = ballCategory;
    ball.physicsBody.contactTestBitMask = brickCategory | paddleCategory | bottomEdgeCategory; // brick, paddle or bottom edge category
    // e.g. this line would disable collision for the paddle
    // ball.physicsBody.collisionBitMask = edgeCategory | brickCategory;
    
    // create orb animation
    SKTextureAtlas *orbAtlas = [SKTextureAtlas atlasNamed:@"orb"];
    
    // get image names and sort them
    NSArray *orbImages = [orbAtlas textureNames];
    NSArray *orbImagesSorted = [orbImages sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    // create an actual texture array
    NSMutableArray *orbTextures = [NSMutableArray array];

    for (NSString *filename in orbImagesSorted) {
        SKTexture *texture = [orbAtlas textureNamed:filename];
        [orbTextures addObject:texture];
    }
    
    // create animation
    SKAction *glow = [SKAction animateWithTextures:orbTextures timePerFrame:0.1];
    
    SKAction *keepGlowing = [SKAction repeatActionForever:glow];

    [ball runAction:keepGlowing];
    
    // add to scene
    [self addChild:ball];
    
    // add a vector to the ball
    CGVector myVector = CGVectorMake(10, 10); // up and to the right
    [ball.physicsBody applyImpulse: myVector];
    
    // FORCE vs. IMPULSE
    // force is applied over time (gravity, spaceship engine, wind, etc)
    // impulse is a singular event (cannonball, bullet, jump)
    
}


- (void) addBricks:(CGSize)size {
    for (int i = 0; i < 4; i++) {
        SKSpriteNode *brick = [SKSpriteNode spriteNodeWithImageNamed:@"brick"];
        
        brick.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:brick.frame.size];
        brick.physicsBody.dynamic = NO;
        brick.physicsBody.categoryBitMask = brickCategory;
        
        int xPos = size.width/5 * (i+1);
        int yPos = size.height - 50;
        
        brick.position = CGPointMake(xPos, yPos);
        [self addChild:brick];
        
    }
}

- (void) addPlayer:(CGSize)size {
    
    // create paddle
    // self.paddle ensures that the object will be assigned to the public property "paddle"
    self.paddle = [SKSpriteNode spriteNodeWithImageNamed:@"paddle"];
    
    self.paddle.position = CGPointMake(size.width/2, 100.0);
    self.paddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.paddle.frame.size];
    self.paddle.physicsBody.dynamic = NO;
    self.paddle.physicsBody.categoryBitMask = paddleCategory;
    
    // add to scene
    [self addChild:self.paddle];
    
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    // called when the user continues to touch the screen
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self]; // where did this specific touch happen? (self refers to scene)
        CGPoint newPosition = CGPointMake(location.x, 100);
        
        // stop the paddle from moving too far
        // restrict its movement
        if (newPosition.x < self.paddle.size.width / 2) {
            newPosition.x = self.paddle.size.width / 2; // left coordinate (0) + half the width of the paddle
        }
        
        if (newPosition.x > self.size.width - (self.paddle.size.width / 2)) {
            newPosition.x = self.size.width - (self.paddle.size.width / 2); // 270 = width of screen - half the width of the paddle
        }
        
        self.paddle.position = newPosition;
        
    }
    
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        /* Init sounds */
        soundPaddleHit = [SKAction playSoundFileNamed:@"blip.caf" waitForCompletion:NO];
        soundBrickHit = [SKAction playSoundFileNamed:@"brickhit.caf" waitForCompletion:NO];
        
        self.backgroundColor = [SKColor blackColor];
        
        // scene's physics body
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];

        // change gravity settings of the scene
        self.physicsWorld.gravity = CGVectorMake(0, 0);
            // 0, 0 = space
            // 0, -1.6 = moon
            // 0, -9.8 = earth
        
            // these are basically coordinate multipliers,
            // so they describe how far to move an object
            // in x/y space under certain forces. if the force
            // is stronger, these numbers will increase
            // proportionally
        
        // make this scene class the delegate for objects
        // making contact. this will ensure that when the
        // scene detects that two objects eligible for
        // contact notifications DO make contact,
        // the two contact methods at the top of this
        // scene will be processed.
        self.physicsWorld.contactDelegate = self;
        
        
        self.physicsBody.categoryBitMask = edgeCategory;
        
        
        [self addBall:size]; // size of scene
        [self addPlayer:size];
        [self addBricks:size];
        [self addBottomEdge:size];
        
    }
    return self;
}


-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
