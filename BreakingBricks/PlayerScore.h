//
//  PlayerScore.h
//  BreakingBricks
//
//  Created by Alex Taylor on 2014-04-26.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface PlayerScore : SKLabelNode

/** Adds a number of points to the player's current score. */
- (void)incrementCurrentScoreBy: (NSInteger)points;

/** Resets the player's current score to the value specified. */
- (void)resetScoreTo: (NSInteger)points;


@end
