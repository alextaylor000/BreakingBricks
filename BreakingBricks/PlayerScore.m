//
//  PlayerScore.m
//  BreakingBricks
//
//  Created by Alex Taylor on 2014-04-26.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "PlayerScore.h"

// constants
static NSString * const playerScoreFontName = @"Futura Medium";
static NSInteger const  playerScoreFontSize = 25;
static NSString * const playerScoreLabel = @"Score: %i";
static NSInteger const  playerScoreAlignment = SKLabelHorizontalAlignmentModeRight;
static NSInteger const  playerScoreInitial = 0;

// score color
static CGFloat const    playerScoreFontColorRed     = 1.0; // R
static CGFloat const    playerScoreFontColorGreen   = 1.0; // G
static CGFloat const    playerScoreFontColorBlue    = 0.0; // B
static CGFloat const    playerScoreFontColorAlpha   = 1.0; // A


@interface PlayerScore ()

- (NSString *) synthesizeTextLabel;

@end

@implementation PlayerScore {
    // stores the score label so we can update it in the class
    SKLabelNode *scoreLabel;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // initialize with a score of zero
        // store this in userdata so that it will be archived automagically
        NSNumber *initialScore = [NSNumber numberWithInt:playerScoreInitial];
        self.userData = [NSMutableDictionary dictionaryWithDictionary:@{@"score": initialScore}];
        
        self.text = [self synthesizeTextLabel];
        self.horizontalAlignmentMode = playerScoreAlignment;
        self.fontName = playerScoreFontName;
        self.fontColor = [SKColor colorWithRed:playerScoreFontColorRed green:playerScoreFontColorGreen blue:playerScoreFontColorBlue alpha:playerScoreFontColorAlpha];
        self.fontSize = playerScoreFontSize;
        
        return self;
    }
    
    return self;

}

- (NSString *) synthesizeTextLabel {
    return [NSString stringWithFormat:playerScoreLabel, [self.userData[@"score"] intValue] ];
}


- (void)incrementCurrentScoreBy: (NSInteger)points {
    // TODO: Verify that the userData dict is storing this value correctly
    NSNumber *currentScore = self.userData[@"score"];
    currentScore = [NSNumber numberWithInteger:(currentScore.integerValue + points)];
    [self.userData setObject:currentScore forKey:@"score"];

    self.text = [self synthesizeTextLabel];
}

- (void)resetScoreTo: (NSInteger)points {
    NSNumber *currentScore = self.userData[@"score"];
    currentScore = [NSNumber numberWithInteger:(points)];
    [self.userData setObject:currentScore forKey:@"score"];
    
    self.text = [self synthesizeTextLabel];
    
}



@end
