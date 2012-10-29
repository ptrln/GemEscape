//
//  MenuScene.m
//  GemEscape
//
//  Implements MenuScene.h
//
//  Created by Peter Lin on 26/04/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "MenuScene.h"
#import "SelectLevelScene.h"
#import "AppDelegate.h"
#import "GameScene.h"
#import "HowToPlayScene.h"
#import "GemEscapeData.h"
@implementation MenuScene

#define GAME_TITLE_FONT_SIZE 64         //  font size of the game title
#define MENU_ITEM_FONT_SIZE 28          //  font size of the menu items
#define MENU_ITEM_PADDING_SIZE 20       //  padding of the menu items
#define MENU_POSITION_Y_OFFSET -50      //  the y offset of the menu for alignment
#define CREDITS_FONT_SIZE 15            //  the font size of the credits section

//  Helper class method that creates a Scene with the GemEscapeLayer as the only child.
+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
    MenuScene *menu = [MenuScene node];
    [scene addChild: menu];
    return scene;
}

//  on "init" you need to initialize your instance
-(id) init
{
	//  always call "super" init
	//  Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init])) {
		// ask director the the window size
		CGSize size = [[CCDirector sharedDirector] winSize];
        
        //  display the menu art and add to scene
        CCSprite *art = [CCSprite spriteWithFile:@"menu_art.png"];
        art.position = ccp(size.width / 2, size.height/ 2);
        [self addChild:art];
        
		// create and initialize a game title and add to scene
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Gem Escape" fontName:@"Marker Felt" fontSize:GAME_TITLE_FONT_SIZE];
		label.position =  ccp( size.width /2 , size.height - GAME_TITLE_FONT_SIZE);
		[self addChild: label];
        
		//  menu to resume, start new game, how to play
        [CCMenuItemFont setFontSize:MENU_ITEM_FONT_SIZE];
        
        CCMenuItem *resumeLastGame = [CCMenuItemFont itemWithString:@"Resume Game" block:^(id sender) {
            [[CCDirector sharedDirector] replaceScene:[GameScene sceneByResumingLastGame]];
        }];
        
        //  if there is no saved progress, disable resume game
        if (! [GemEscapeData savedLevelProgress])
            [resumeLastGame setIsEnabled:NO];
                    
        CCMenuItem *startNewGame = [CCMenuItemFont itemWithString:@"New Game" block:^(id sender) {
            [[CCDirector sharedDirector] replaceScene:[SelectLevelScene scene]];
        }];
        
        CCMenuItem *howToPlay = [CCMenuItemFont itemWithString:@"How To Play" block:^(id sender) {
            [[CCDirector sharedDirector] pushScene:[HowToPlayScene scene]];
        }];
        
        //  leader board is disabled because it is not implemented
		//  leaderboard Menu Item using blocks
        /*
        CCMenuItem *itemLeaderboard = [CCMenuItemFont itemWithString:@"Leaderboard" block:^(id sender) {
			GKLeaderboardViewController *leaderboardViewController = [[GKLeaderboardViewController alloc] init];
			leaderboardViewController.leaderboardDelegate = self;
			AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
			[[app navController] presentModalViewController:leaderboardViewController animated:YES];
			
		}];
        
        itemLeaderboard.isEnabled = NO;
		CCMenu *menu = [CCMenu menuWithItems:resumeLastGame, startNewGame, howToPlay, itemLeaderboard, nil];
		*/
        
		CCMenu *menu = [CCMenu menuWithItems:resumeLastGame, startNewGame, howToPlay, nil];
        [menu alignItemsVerticallyWithPadding:MENU_ITEM_PADDING_SIZE];
		[menu setPosition:ccp(size.width/2, size.height/2 + MENU_POSITION_Y_OFFSET)];
        [self addChild:menu];
        
        //  a credits section at the buttom
        CCLabelTTF *me = [CCLabelTTF labelWithString:@"Made by Peter Lin" fontName:@"Marker Felt" fontSize:CREDITS_FONT_SIZE];
		me.position =  ccp(size.width/2 , CREDITS_FONT_SIZE);
		[self addChild: me];
	}
	return self;
}

#pragma mark GameKit delegate

//  this is used to display the leader board, but it is not implemented
//  only brings up an empty leader board, don't use this yet!
-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}


@end
