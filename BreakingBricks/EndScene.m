//
//  EndScene.m
//  BreakingBricks
//
//  Created by Alex Taylor on 2014-04-25.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "MyScene.h"
#import "EndScene.h"

@implementation EndScene

- (instancetype)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {

        self.backgroundColor = [SKColor orangeColor];
        
        SKAction *play = [SKAction playSoundFileNamed:@"gameover.caf" waitForCompletion:NO];
        [self runAction:play];
        
        
        SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
        label.text = @"GAME OVER!";
        label.fontColor = [SKColor yellowColor];
        label.fontSize = 44;
        label.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        [self addChild: label];
        
        
        SKLabelNode *tryAgain = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
        tryAgain.text = @"Play again?";
        tryAgain.fontColor = [SKColor yellowColor];
        tryAgain.fontSize = 26;
        tryAgain.position = CGPointMake(size.width/2, -50);
        
        SKAction *moveLabel = [SKAction moveToY:(size.height/2 - 40) duration:0.4];
        [tryAgain runAction:moveLabel];
        
        [self addChild:tryAgain];
        
        
    }
    
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    MyScene *myScene = [MyScene sceneWithSize:self.size];
    [self.view presentScene:myScene transition:[SKTransition doorsOpenHorizontalWithDuration:1.2]];
}

@end
