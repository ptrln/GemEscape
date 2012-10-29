//
//  GemEscapeLayer.h
//  GemEscape
//
//  This is the game scene that the gem escape game is played.
//
//  Created by Peter Lin on 14/04/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//
#import "cocos2d.h"
@interface GameScene : CCLayer

//  returns a CCScene that contains the GameScene as the only child. this method is required by cocos2d.
//  this method is used when the scene should begin with a new game.
+(CCScene *) sceneWithStartingLevelNumber: (int) level;

//  returns a CCScene that contains the GameScene as the only child. this method is required by cocos2d.
//  this method is used when the scene should begin by resuming a game that's saved.
+(CCScene *) sceneByResumingLastGame;
@end
