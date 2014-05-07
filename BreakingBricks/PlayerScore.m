//
//  PlayerScore.m
//  BreakingBricks
//
//  Created by Alex Taylor on 2014-04-26.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "PlayerScore.h"

// constants
static NSString * const playerScoreFontName = @"Helvetica-Bold";
static NSInteger const  playerScoreFontSize = 25;
static NSInteger const  playerScoreAlignment = SKLabelHorizontalAlignmentModeRight;

static NSString * const playerEventFontName = @"Helvetica-Light";
static NSInteger const  playerEventFontSize = 35;
static NSInteger const  playerEventAlignment = SKLabelHorizontalAlignmentModeCenter;

static NSString * const playerScoreLabel = @"%i";

static NSInteger const  playerScoreInitial = 0;

// score color
static CGFloat const    playerScoreFontColorRed     = 0.29; // R
static CGFloat const    playerScoreFontColorGreen   = 0.29; // G
static CGFloat const    playerScoreFontColorBlue    = 0.29; // B
static CGFloat const    playerScoreFontColorAlpha   = 1.0; // A

static CGFloat const    playerEventFontColorRed     = 1; // R
static CGFloat const    playerEventFontColorGreen   = 0; // G
static CGFloat const    playerEventFontColorBlue    = 0.706; // B
static CGFloat const    playerEventFontColorAlpha   = 1.0; // A




@interface PlayerScore ()

- (NSString *) synthesizeTextLabel;

@end

@implementation PlayerScore {
    // stores the score label so we can update it in the class
    SKLabelNode *scoreLabel;
    
    
    SKLabelNode *eventLabel;
    SKAction *eventLabelFadesOut;
    
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

- (SKLabelNode *)addEventLabel {
    eventLabel = [SKLabelNode labelNodeWithFontNamed:playerEventFontName];
    eventLabel.horizontalAlignmentMode = playerEventAlignment;
    eventLabel.fontSize = playerEventFontSize;
    eventLabel.fontColor = [SKColor colorWithRed:playerEventFontColorRed green:playerEventFontColorGreen blue:playerEventFontColorBlue alpha:playerEventFontColorAlpha];
    // init the fade-out action
    eventLabelFadesOut = [SKAction fadeOutWithDuration:0.4];
    
    return eventLabel;

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
    
    if (eventLabel) {
        // end any existing actions
        [eventLabel removeAllActions];
        
        // reset the transparency
        eventLabel.alpha = 1.0;
        eventLabel.text = [NSString stringWithFormat:@"%+d", points];
        [eventLabel runAction:eventLabelFadesOut];
    }
    
}

- (void)resetScoreTo: (NSInteger)points {
    NSNumber *currentScore = self.userData[@"score"];
    currentScore = [NSNumber numberWithInteger:(points)];
    [self.userData setObject:currentScore forKey:@"score"];
    
    self.text = [self synthesizeTextLabel];
    
}



@end
