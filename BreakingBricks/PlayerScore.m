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
        self.currentScore = 0;
        self.text = [self synthesizeTextLabel];
        self.horizontalAlignmentMode = playerScoreAlignment;
        self.fontName = playerScoreFontName;
        self.fontColor = [SKColor colorWithRed:playerScoreFontColorRed green:playerScoreFontColorGreen blue:playerScoreFontColorBlue alpha:playerScoreFontColorAlpha];
        
        return self;
    }
    
    return self;

}

- (NSString *) synthesizeTextLabel {

    return [NSString stringWithFormat:playerScoreLabel, self.currentScore];
}

//- (SKLabelNode *) newLabelNode {
//    
//    // create a label node with the attribs above and return it
//    scoreLabel = [SKLabelNode labelNodeWithFontNamed:fontName];
//    scoreLabel.text = [self synthesizeTextLabel];
//    
//    scoreLabel.horizontalAlignmentMode = playerScoreAlignment;
//    scoreLabel.fontColor = [SKColor colorWithRed:playerScoreFontColorRed green:playerScoreFontColorGreen blue:playerScoreFontColorBlue alpha:playerScoreFontColorAlpha];
//    
//    // return the label for placement in scene
//    return scoreLabel;
//}


- (void)incrementCurrentScoreBy: (NSInteger)points {

    self.currentScore += points;
    self.text = [self synthesizeTextLabel];
}

- (void)resetScoreTo: (NSInteger)points {
    self.currentScore = points;
    self.text = [self synthesizeTextLabel];
    
}



@end
