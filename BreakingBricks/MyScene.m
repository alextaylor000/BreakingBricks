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


// sizes for graphics
// these are different than the actual image sizes because of the glows and shadows
static const CGFloat    graphicsPaddleWidth     =   101;
static const CGFloat    graphicsPaddleHeight    =   16;

static const CGFloat    graphicsBrickWidth      =   60;
static const CGFloat    graphicsBrickHeight     =   30;

static const CGFloat    graphicsBallDiameter    =   27;


// scores
static const NSInteger  scoreGoodBrick          =   15;
static const NSInteger  scoreBadBrick           =   -5;
static const NSInteger  scoreMissedGoodBrick        =   -10;



@implementation MyScene {
    // in-game sounds; alloc'd here so there's no pause when the sounds are loaded
    SKAction *soundPaddleHit;
    SKAction *soundBrickHit;
    SKAction *soundBrickHitBad;

    // action for moving bricks. this gets called during init AND during evaluateAction
    SKAction *moveBricks;
    SKAction *moveBricksForever;
    
    // ball should be accessible for changing its speed
    SKSpriteNode *ball;
    
    // make the brickContainer accessible so we can move it in the game loop
    SKSpriteNode *brickContainer;

    // keep track of the last brick to know when to add more
    SKSpriteNode *lastBrick ;
    
    // score properties
    PlayerScore *myScore;
    SKLabelNode *myScoreEvent;
    
    // timer properties
    NSTimeInterval startTime;
    NSTimeInterval elapsedTime;
    NSTimeInterval lastLevelUpdate; // the time of the last level update, to make sure it only updates once per interval
    
    // speed properties
    // beginning velocities of objects
    CGFloat ballSpeed;
    CGFloat bricksSpeed;

    // difficulty properties
    NSInteger levelUpdateInterval; // how many seconds to update the level
    CGFloat levelDifficultyInterval; // percentage to increase speed by
    NSInteger currentLevel;
    
    SKTexture *brickGood;
    SKTexture *brickBad;
    
    SKTexture *levelOn;
    SKTexture *levelOff;
    
    SKEmitterNode *brickDesctruction;
    
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
- (void)destroyBrick:(SKNode *)nodeToDestroy {
    
    SKEmitterNode *brickGoesBoom = [brickDesctruction copy];
    
    CGPoint nodePositionInScene = [nodeToDestroy.scene convertPoint:nodeToDestroy.position fromNode:nodeToDestroy.parent];
    
    // BOOM!
    brickGoesBoom.position = nodePositionInScene;
    [self addChild:brickGoesBoom];
    brickGoesBoom.numParticlesToEmit = 30;
    
    [nodeToDestroy removeFromParent];
    
    // TODO: does this result in lots of stale references to particle emitters??

}

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
        // BOOM!
        [self destroyBrick:notTheBall.node];
        

        // update score
        [myScore incrementCurrentScoreBy:scoreGoodBrick];
        
    }

    
    if (notTheBall.categoryBitMask == brickBadCategory) {
        [self runAction:soundBrickHitBad];
        
        // BOOM!
        [self destroyBrick:notTheBall.node];
        
        
        // update score
        [myScore incrementCurrentScoreBy:scoreBadBrick];
        
    }

    
    
    if (notTheBall.categoryBitMask == paddleCategory) {
        
        [self runAction:soundPaddleHit];
    }
    
    if (notTheBall.categoryBitMask == bottomEdgeCategory) {
//        EndScene *end = [EndScene sceneWithSize:self.size];
//        [self.view presentScene:end transition:[SKTransition doorsCloseHorizontalWithDuration:0.5]];
        
    }
    
    
}


- (void)addScoreEvent:(CGSize) size {
    // TODO: refactor this into PlayerScore
    myScoreEvent = [myScore addEventLabel];
    
    myScoreEvent.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    [self addChild:myScoreEvent];
}

- (void)addBottomEdge:(CGSize) size {
    // the "game over" edge at the bottom
    SKNode *bottomEdge = [SKNode node]; // this acts as an invisible container so we can give it a physics body
    bottomEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(0, 1) toPoint:CGPointMake(self.size.width, 1)];
    bottomEdge.physicsBody.categoryBitMask = bottomEdgeCategory;
    
    [self addChild:bottomEdge];
    
}

- (void)addLevelIndicator:(CGSize)size forLevel: (NSInteger)level {

    
    SKLabelNode *levelIndicator = [SKLabelNode labelNodeWithFontNamed:@"AmericanTypewriter-Bold"];
    levelIndicator.position = CGPointMake((level * 15), 10);
    levelIndicator.fontSize = 50;
    levelIndicator.text = @".";
    levelIndicator.fontColor = [SKColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
    levelIndicator.alpha = 0.0;
    SKAction *fadeIn = [SKAction fadeInWithDuration:0.25];
    
    [self addChild:levelIndicator];
    [levelIndicator runAction:fadeIn];
    
    
    
}

- (void)addBall:(CGSize)size
{
    // create sprite
    ball = [SKSpriteNode spriteNodeWithImageNamed:@"ball_yellow"];
    
    CGPoint myPoint = CGPointMake(size.width/2, size.height - 75);
    //ball.size = CGSizeMake(27, 27);
    ball.position = myPoint;
    
    // add physics body to ball
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:graphicsBallDiameter/2];
    
    
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
    
    // add to scene
    [self addChild:ball];
    
    // add a vector to the ball
    CGVector myVector = CGVectorMake(2, ballSpeed);
    [ball.physicsBody applyImpulse: myVector];
    
    // FORCE vs. IMPULSE
    // force is applied over time (gravity, spaceship engine, wind, etc)
    // impulse is a singular event (cannonball, bullet, jump)
    
}


- (void) addBrickContainer:(CGSize)size startingAt:(CGPoint)brickContainerPos {
    // create a container node to hold all the bricks so we can control the group's speed

    brickContainer = [SKSpriteNode spriteNodeWithColor:[SKColor darkGrayColor] size:CGSizeMake(1, 1)]; // this doesn't need to be a size, the children can exceed its bounds
    
    brickContainer.position = brickContainerPos;
    
    [self addChild:brickContainer];
    
}


- (void) addBricks:(CGSize)size numberOfBricks:(NSInteger)numBricks startingAt:(CGPoint)brickPos {
    // adds x number of bricks starting at anchor point x
    
    
    for (int i = 0; i < numBricks; i++) {
        

        
        SKSpriteNode *brick = [SKSpriteNode spriteNodeWithTexture:brickGood];
        
        
        brick.name = @"brick";

        
        // commented this out because I think it was interfering with the physics body
        //brick.anchorPoint = CGPointMake(0, 0); // make the anchor point bottom-left instead of center
        brick.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(graphicsBrickWidth, graphicsBrickHeight)];
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
        
        brick.position = CGPointMake(brickPos.x, brickPos.y);
        
        CGFloat brickWidth = brick.size.width;
        
        // update the position for the next brick
        brickPos = CGPointMake( (brickPos.x + brickWidth + 5), brickPos.y);
        
        // debug
        NSLog(@"Brick container size is %0fx%0f", brickContainer.frame.size.width, brickContainer.frame.size.height);
        NSLog(@"(%i) Adding brick '%@' at %0f, %0f with category %u", i, brick.name, brick.position.x, brick.position.y, brick.physicsBody.categoryBitMask);

        if (brick.physicsBody.categoryBitMask == brickBadCategory) {
            brick.texture = brickBad;
        }
        
        
        [brickContainer addChild:brick];
        
        if (i == (numBricks - 1)) {
            lastBrick = brick;
        }
        
    }
}

- (void) addPlayer:(CGSize)size {
    
    // create paddle
    // self.paddle ensures that the object will be assigned to the public property "paddle"
    self.paddle = [SKSpriteNode spriteNodeWithImageNamed:@"paddle_teal"];
    
    self.paddle.position = CGPointMake(size.width/2, 50.0);
    self.paddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize: CGSizeMake(graphicsPaddleWidth, graphicsPaddleHeight)];
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
        currentLevel = 1;
        
        /* Init sounds */
        soundPaddleHit = [SKAction playSoundFileNamed:@"blip.caf" waitForCompletion:NO];
        soundBrickHit = [SKAction playSoundFileNamed:@"brickhit.caf" waitForCompletion:NO];
        soundBrickHitBad = [SKAction playSoundFileNamed:@"brickhit.caf" waitForCompletion:NO];
        
        /* Init textures */
        brickGood = [SKTexture textureWithImageNamed:@"brick_good"];
        brickBad = [SKTexture textureWithImageNamed:@"brick_bad"];
        levelOn = [SKTexture textureWithImageNamed:@"level_on"];
        levelOff = [SKTexture textureWithImageNamed:@"level_off"];
        
        /* init particles */
        brickDesctruction = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle]pathForResource:@"BrickDestruction" ofType:@"sks"]];

        
        // background image
        SKSpriteNode *backgroundImage = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
        backgroundImage.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        [self addChild:backgroundImage];
        
        
        
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
        
        
        [self addBall:size]; // size of scene
        [self addPlayer:size];
        [self addBrickContainer:size startingAt:CGPointMake(self.frame.size.width/2 + 25, size.height - 25)];
        [self addBricks:size numberOfBricks:10 startingAt:CGPointMake(0, 0)]; // just test coords for now

        // fade in the bricks
        brickContainer.alpha = 0.0;
        SKAction *fadeIn = [SKAction fadeInWithDuration:1.0];
        [brickContainer runAction:fadeIn];
        
        [self addBottomEdge:size];
        
        // add score
        //[self addScore:size withScore:currentScore];
        myScore = [[PlayerScore alloc]init];
        myScore.position = CGPointMake(self.frame.size.width - 10, 10);
        [self addChild:myScore];
        
        // add event label
        // TODO: refactor this into the PlayerScore somehow
        [self addScoreEvent:size];
        
        // add difficulty indicator
        [self addLevelIndicator:size forLevel:1];

        
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
    
    // remove old bricks
    [self enumerateChildNodesWithName:@"//brick" usingBlock:^(SKNode *node, BOOL *stop) {
        CGPoint nodePositionInScene = [node.scene convertPoint:node.position fromNode:node.parent];
        if (nodePositionInScene.x < (0 - (node.frame.size.width/2) )   ) {
            NSLog(@"Removing brick");

            
            if (node.physicsBody.categoryBitMask == brickCategory) {
                // decrement score if it's a good brick
                [myScore incrementCurrentScoreBy:scoreMissedGoodBrick];
            }

            [node removeFromParent];
            
            
            // TODO: Even though we're removing bricks, the memory usage is still going up. Maybe we need to actually destroy them?
            // this is pretty brilliant way of removing obstacles, from http://roadtonerdvana.com/2014/04/24/tapity-tapper-my-ios-flappy-bird-clone-using-sprite-kit-adding-obstacles/:
//            [upperObstacle runAction:moveObstacle completion:^(void){
//                [upperObstacle removeFromParent];
//            }];
//            [lowerObstacle runAction:moveObstacle completion:^(void){
//                [lowerObstacle removeFromParent];
//            }];
        }
    }];
    
    // increase the speed!
    // if the elapsed time is more than 1 second and the level interval has arrived
    if ( (int)elapsedTime > 1 && (int)elapsedTime % levelUpdateInterval == 0) {
        
        // the last level update stores the game time when the level was last updated.
        // this if block prevents the level from updating more than once within a second
        // since elapsedTime as an int will evaluate the same for ~60 frames in a row!
        if (elapsedTime - lastLevelUpdate > 1.0 ) {
            currentLevel += 1;
            
            [self addLevelIndicator:self.size forLevel:currentLevel];
            
            NSLog(@"** LEVEL INCREASED! ***");
            
            ballSpeed = (1 + levelDifficultyInterval);
            bricksSpeed *= (1 + levelDifficultyInterval);
            
            // cancel brick actions and update the speed
            [brickContainer removeAllActions];
            [self moveBricksInSceneBySpeed:bricksSpeed];
            NSLog(@"Moving bricks @ %01.f", bricksSpeed);
            

            
            // add a vector to the ball
            SKAction *ballFadeToOrange = [SKAction colorizeWithColor:[SKColor orangeColor] colorBlendFactor:0.75 duration:0.15];
            SKAction *ballFadeFromOrange = [SKAction colorizeWithColor:[SKColor whiteColor] colorBlendFactor:0 duration:0.15];
            SKAction *ballLevelsUp = [SKAction sequence:@[ballFadeToOrange, ballFadeFromOrange]];
            [ball runAction:ballLevelsUp];
            
            NSLog(@": Ball is travelling at vector %0.1f, %01.f", ball.physicsBody.velocity.dx, ball.physicsBody.velocity.dy);
            
            // we need to apply an impulse to the ball to give it another push
            // so we need to get a ratio of how fast the ball is travelling in both directions
            // to do this, we'll take the ball's current velocity and express it as a percentage
            // then, to speed the ball up, we can multiply that by the ball speed
            
            // I've set the ball speed to just be the levelDifficultyInterval, this may need
            // to be tweaked to get a good feeling of speed
            
            NSLog(@"Ball's mass is %0.f", ball.physicsBody.mass);
            [ball.physicsBody applyImpulse:CGVectorMake(0.0, 1.0)];
            
//            CGVector myVector = CGVectorMake((100/ball.physicsBody.velocity.dx)*ballSpeed, (100/ball.physicsBody.velocity.dy)*ballSpeed);
//            [ball.physicsBody applyImpulse: myVector];
            NSLog(@"+ Ball is travelling at vector %0.1f, %01.f", ball.physicsBody.velocity.dx, ball.physicsBody.velocity.dy);
            
            
            
            // we just updated the level, so set the lastLevelUpdate to the current elapsed time
            lastLevelUpdate = elapsedTime;
        }
        
        
    }
    

}



- (void)didEvaluateActions {
    // this could also be done with an action, too.
    // check out http://roadtonerdvana.com/2014/04/24/tapity-tapper-my-ios-flappy-bird-clone-using-sprite-kit-adding-obstacles/
    
    

    
    // track lastBrick's position relative to the scene
    // if lastBrick's position (its center) passes the right edge of the scene (defined by the scene width),
    // then we need to add more bricks
    CGPoint lastBrickPositionInScene = [lastBrick.scene convertPoint:lastBrick.position fromNode:lastBrick.parent];
    //NSLog(@"lastBrickPositionInScene x=%0.1f", lastBrickPositionInScene.x);

    if (lastBrickPositionInScene.x < self.frame.size.width) {
        NSLog(@"lastBrick is entering the scene space. Time to add more bricks!");
        //[self addBricks:self.size numberOfBricks:10 startingAt:CGPointMake((lastBrickPositionInScene.x + lastBrick.size.width + 5), (self.size.height - 25))];
        [self addBricks:self.size numberOfBricks:10 startingAt:CGPointMake(lastBrick.position.x + lastBrick.size.width + 5, 0)];

    }
    
}


@end
