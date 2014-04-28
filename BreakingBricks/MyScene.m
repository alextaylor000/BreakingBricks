//
//  MyScene.m
//  BreakingBricks
//
//  Created by Alex Taylor on 2014-04-22.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "MyScene.h"
#import "EndScene.h"
#import "PlayerScore.h"

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
static const uint32_t brickBadCategory  = 0x1 << 5;


@implementation MyScene {
    // in-game sounds; alloc'd here so there's no pause when the sounds are loaded
    SKAction *soundPaddleHit;
    SKAction *soundBrickHit;
    SKAction *soundBrickHitBad;

    // action for moving bricks. this gets called during init AND during evaluateAction
    SKAction *moveBricks;
    SKAction *moveBricksForever;
    
    // make the brickContainer accessible so we can move it in the game loop
    SKSpriteNode *brickContainer;

    // keep track of the last brick to know when to add more
    SKSpriteNode *lastBrick ;
    
    // score properties
    SKLabelNode *scoreLabel;
    NSInteger currentScore;
    
    // timer properties
    NSTimeInterval startTime;
    NSTimeInterval elapsedTime;
    NSTimeInterval lastLevelUpdate; // the time of the last level update, to make sure it only updates once per interval
    
    // speed properties
    CGFloat ballSpeed;
    CGFloat bricksSpeed;
    
    // difficulty properties
    NSInteger levelUpdateInterval; // how many seconds to update the level
    CGFloat levelDifficultyInterval; // percentage to increase speed by

}


// Functions for random numbers
static inline CGFloat skRandf() {
    return rand() / (CGFloat) RAND_MAX;
}

static inline CGFloat skRand(CGFloat low, CGFloat high)
{
    return skRandf() * (high - low) + low;
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

        // update score
        [self updateScoreWithIncrement:1];
        
    }

    
    if (notTheBall.categoryBitMask == brickBadCategory) {
        [self runAction:soundBrickHitBad];
        [notTheBall.node removeFromParent];
        
        // update score
        [self updateScoreWithIncrement:-1];
        
    }

    
    
    if (notTheBall.categoryBitMask == paddleCategory) {
        
        [self runAction:soundPaddleHit];
    }
    
    if (notTheBall.categoryBitMask == bottomEdgeCategory) {
//        EndScene *end = [EndScene sceneWithSize:self.size];
//        [self.view presentScene:end transition:[SKTransition doorsCloseHorizontalWithDuration:0.5]];
        
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
    SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"ball"];
    
    CGPoint myPoint = CGPointMake(size.width/2, size.height - 75);
    //ball.size = CGSizeMake(27, 27);
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
    
    // setting this to 1 means NO energy is lost; e.g. after the bounce, it has
    // THIS VALUE of its previous energy. so 100% means it has 100% of its
    // previous energy
    ball.physicsBody.restitution = 1;
    
    ball.physicsBody.angularDamping = 0;
    
    // prevents the ball from being affected by brick hits
    ball.physicsBody.allowsRotation = NO;
    
    // set categories
    ball.physicsBody.categoryBitMask = ballCategory;
    ball.physicsBody.contactTestBitMask = brickCategory | brickBadCategory | paddleCategory | bottomEdgeCategory; // brick, paddle or bottom edge category
    // e.g. this line would disable collision for the paddle
    // ball.physicsBody.collisionBitMask = edgeCategory | brickCategory;
    
//    // create orb animation
//    SKTextureAtlas *orbAtlas = [SKTextureAtlas atlasNamed:@"orb"];
//    
//    // get image names and sort them
//    NSArray *orbImages = [orbAtlas textureNames];
//    NSArray *orbImagesSorted = [orbImages sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
//    
//    // create an actual texture array
//    NSMutableArray *orbTextures = [NSMutableArray array];
//
//    for (NSString *filename in orbImagesSorted) {
//        SKTexture *texture = [orbAtlas textureNamed:filename];
//        [orbTextures addObject:texture];
//    }
//    
//    // create animation
//    SKAction *glow = [SKAction animateWithTextures:orbTextures timePerFrame:0.1];
//    
//    SKAction *keepGlowing = [SKAction repeatActionForever:glow];
//
//    [ball runAction:keepGlowing];
    
    // add to scene
    [self addChild:ball];
    
    // add a vector to the ball
    CGVector myVector = CGVectorMake(2, ballSpeed);
    [ball.physicsBody applyImpulse: myVector];
    
    // FORCE vs. IMPULSE
    // force is applied over time (gravity, spaceship engine, wind, etc)
    // impulse is a singular event (cannonball, bullet, jump)
    
}


- (void) addBricks:(CGSize)size numberOfBricks:(NSInteger)numBricks startingAt:(CGPoint)brickPos {
    // adds x number of bricks starting at anchor point x
    
    // create a container node to hold all the bricks so we can control the group's speed

    brickContainer = [SKSpriteNode spriteNodeWithColor:[SKColor darkGrayColor] size:CGSizeMake(1, 1)]; // this doesn't need to be a size, the children can exceed its bounds


    
    
    brickContainer.position = brickPos;
    
    [self addChild:brickContainer];
    
    brickPos = CGPointMake(0, 0); // reset the brickPos to be relative to the container
    
    
    for (int i = 0; i < numBricks; i++) {
        
        SKSpriteNode *brick = [SKSpriteNode spriteNodeWithImageNamed:@"brick"];
        
        
        brick.name = @"brick";
        
        

        
        // commented this out because I think it was interfering with the physics body
        //brick.anchorPoint = CGPointMake(0, 0); // make the anchor point bottom-left instead of center
        brick.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:brick.frame.size];
        brick.physicsBody.dynamic = NO;

        brick.physicsBody.friction = 0;

        // randomly throw in a "bad" brick
        CGFloat random = skRand(0.0, 1.0);


        if (random <= 0.1) {
            brick.physicsBody.categoryBitMask = brickBadCategory;
        } else {
            brick.physicsBody.categoryBitMask = brickCategory;
        }

    
        // place the brick
        
        
        //brick.position = CGPointMake(brickPos.x + (brick.size.width/2), brickPos.y);
        brick.position = CGPointMake(brickPos.x, brickPos.y);
        
        CGFloat brickWidth = brick.size.width;
        
        // update the position for the next brick
        brickPos = CGPointMake( (brickPos.x + brickWidth + 5), brickPos.y);
        
        // debug
        NSLog(@"Brick container size is %0fx%0f", brickContainer.frame.size.width, brickContainer.frame.size.height);
        NSLog(@"(%i) Adding brick '%@' at %0f, %0f with category %u", i, brick.name, brick.position.x, brick.position.y, brick.physicsBody.categoryBitMask);
        SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
        label.text = [NSString stringWithFormat:@"%@%i", brick.name, i] ;

        if (brick.physicsBody.categoryBitMask == brickBadCategory) {
            label.fontColor = [SKColor redColor];
            
        } else if (brick.physicsBody.categoryBitMask == brickCategory)  {
            label.fontColor = [SKColor blueColor];
        } else {
            label.fontColor = [SKColor greenColor];
        }
        
        
        label.fontSize = 10;
        label.position = CGPointMake(0, 0);
        [brick addChild:label];

        
        
        [brickContainer addChild:brick];
        
        if (i == (numBricks - 1)) {
            lastBrick = brick;
        }
        
    }
}

- (void) addPlayer:(CGSize)size {
    
    // create paddle
    // self.paddle ensures that the object will be assigned to the public property "paddle"
    self.paddle = [SKSpriteNode spriteNodeWithImageNamed:@"paddle"];

    
    self.paddle.position = CGPointMake(size.width/2, 50.0);
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
        CGPoint newPosition = CGPointMake(location.x, 50.0);
        
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

- (void)addScore:(CGSize)size withScore:(NSInteger)score {
    scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
    scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
    scoreLabel.text = [NSString stringWithFormat:@"Score: %i", score];
    scoreLabel.fontColor = [SKColor yellowColor];
    scoreLabel.fontSize = 25;
    scoreLabel.position = CGPointMake(self.frame.size.width - 10, 10);
    [self addChild: scoreLabel];

}

- (void)updateScoreWithIncrement:(NSInteger)score {
    currentScore = currentScore + score;
    scoreLabel.text = [NSString stringWithFormat:@"Score: %i" , currentScore];
}


-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        // start the timers
        startTime = [NSDate timeIntervalSinceReferenceDate];
        elapsedTime = [NSDate timeIntervalSinceReferenceDate];
        
        // set the initial speeds
        ballSpeed = -10.0;
        bricksSpeed = -15.0;

        // set the difficulty
        levelUpdateInterval = 10;
        levelDifficultyInterval = 0.1;
        
        /* Setup your scene here */
        
        currentScore = 0;

        /* Init sounds */
        soundPaddleHit = [SKAction playSoundFileNamed:@"blip.caf" waitForCompletion:NO];
        soundBrickHit = [SKAction playSoundFileNamed:@"brickhit.caf" waitForCompletion:NO];
        soundBrickHitBad = [SKAction playSoundFileNamed:@"brickhit.caf" waitForCompletion:NO];
        
        self.backgroundColor = [SKColor blackColor];
        
        // scene's physics body
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        self.physicsBody.friction = 0;

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
        
        
        //[self addBall:size]; // size of scene
        [self addPlayer:size];
        [self addBricks:size numberOfBricks:10 startingAt:CGPointMake(40, (size.height - 25))]; // just test coords for now
        [self addBottomEdge:size];
        
        // add score
        [self addScore:size withScore:currentScore];

        
        // move the bricks
        [self moveBricksInSceneBySpeed:bricksSpeed];
        
        
    }
    return self;
}

-(void)moveBricksInSceneBySpeed:(CGFloat)speed {
    // moves the brick container

    moveBricks = [SKAction moveByX:speed y:0 duration:1.0];
    moveBricksForever = [SKAction repeatActionForever:moveBricks];
    
    [brickContainer runAction:moveBricksForever];
    
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    // get elapsed time
    NSTimeInterval currentGameTime = [NSDate timeIntervalSinceReferenceDate];
    elapsedTime = currentGameTime - startTime;
    NSLog(@"elapsed time: %i", (int)elapsedTime);
    
    // remove old bricks
    [self enumerateChildNodesWithName:@"//brick" usingBlock:^(SKNode *node, BOOL *stop) {
        CGPoint nodePositionInScene = [node.scene convertPoint:node.position fromNode:node.parent];
        if (nodePositionInScene.x < (0 - (node.frame.size.width/2) )   ) {
            NSLog(@"Removing brick");
            [node removeFromParent];
            // TODO: Even though we're removing bricks, the memory usage is still going up. Maybe we need to actually destroy them?
        }
    }];
    
    // increase the speed!
    // if the elapsed time is more than 1 second and the level interval has arrived
    if ( (int)elapsedTime > 1 && (int)elapsedTime % levelUpdateInterval == 0) {
        
        // the last level update stores the game time when the level was last updated.
        // this if block prevents the level from updating more than once within a second
        // since elapsedTime as an int will evaluate the same for ~60 frames in a row!
        if (elapsedTime - lastLevelUpdate > 1.0 ) {
            NSLog(@"** LEVEL INCREASED! ***");
            
            // increase the speed of ball and bricks by the percentage defined in levelDifficultyInterval
            //ballSpeed += 0.1;
            //bricksSpeed += 0.1;
            
            
            NSLog(@"Ballspeed is now %0.1f, brickspeed is %0.1f", ballSpeed, bricksSpeed);
            
            // we just updated the level, so set the lastLevelUpdate to the current elapsed time
            lastLevelUpdate = elapsedTime;
        }
        
        
    }
    

}



- (void)didEvaluateActions {

    // track lastBrick's position relative to the scene
    // if lastBrick's position (its center) passes the right edge of the scene (defined by the scene width),
    // then we need to add more bricks
    CGPoint lastBrickPositionInScene = [lastBrick.scene convertPoint:lastBrick.position fromNode:lastBrick.parent];
    //NSLog(@"lastBrickPositionInScene x=%0.1f", lastBrickPositionInScene.x);

    if (lastBrickPositionInScene.x < self.frame.size.width) {
        NSLog(@"lastBrick is entering the scene space. Time to add more bricks!");
        [self addBricks:self.size numberOfBricks:10 startingAt:CGPointMake((lastBrickPositionInScene.x + lastBrick.size.width + 5), (self.size.height - 25))];


        // move the bricks
        [self moveBricksInSceneBySpeed:bricksSpeed];

    }
    
}

- (void)didSimulatePhysics
{
    // remove bricks if they pass the left edge
//    [self enumerateChildNodesWithName:@"brick" usingBlock:
//     ^(SKNode *node, BOOL *stop) {
//         if (node.position.x < (0 - (node.frame.size.width/2)))
//
//             [node removeFromParent];
//     }];
}




@end
