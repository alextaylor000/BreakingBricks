//
//  ViewController.m
//  BreakingBricks
//
//  Created by Alex Taylor on 2014-04-22.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "ViewController.h"
#import "MyScene.h"

@implementation ViewController


-(void)viewWillLayoutSubviews {
    // putting all the view code in here and removing viewDidLoad to support landscape orientation
    
    // Configure the view.
    SKView * skView = (SKView *)self.view;
//    skView.showsFPS = YES;
//    skView.showsNodeCount = YES;
    
    if (!skView.scene ) {
        // only create scene if there is not yet a scene object
        // this is necessary because viewWillLayoutSubviews is
        // called multiple times in the app lifecycle
        
        // Create and configure the scene.
        // Create and configure the scene.
        SKScene * scene = [MyScene sceneWithSize:skView.bounds.size];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        
        // Present the scene.
        [skView presentScene:scene];
        
    }
    
}


-(BOOL)prefersStatusBarHidden {
    return YES;
}



- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
