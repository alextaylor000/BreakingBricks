//
//  MyScene.h
//  BreakingBricks
//

//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface MyScene : SKScene <SKPhysicsContactDelegate>
    // add the SKPhysicsContactDelegate protocol so
    // we can be notified when objects make contact
    // with one another

@end
