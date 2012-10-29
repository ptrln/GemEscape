//
//  SelectLevelScene.m
//  GemEscape
//
//  Implements SelectLevelScene.h
//
//  Created by Peter Lin on 26/04/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "SelectLevelScene.h"
#import "GameScene.h"
#import "MenuScene.h"
#import "GemEscapeData.h"

@implementation SelectLevelScene

#define BACK_TEXT_SIZE 25       //  the text size of the "Back To Menu" button
#define LEVELS_PADDING 10       //  padding between each level button
#define TITLE_TEXT_SIZE 32      //  font size of the "Select a level" text

//  Helper class method that creates a Scene with the GemEscapeLayer as the only child.
+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
    SelectLevelScene *menu = [SelectLevelScene node];
    [scene addChild: menu];
    return scene;
}

//  on "init" you need to initialize your instance
-(id) init
{
	//  always call "super" init
	//  Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init])) {
		
		//  create and initialize a Label
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Select a level" fontName:@"Marker Felt" fontSize:TITLE_TEXT_SIZE];
        CGSize size = [[CCDirector sharedDirector] winSize];
		label.position =  ccp(size.width /2 , size.height - TITLE_TEXT_SIZE);
        [self addChild: label];
        
        //  get total number of levels
        int numLevels = [[GemEscapeData levelsData] count];
                
        //  get current highest level completed
        int highestLevelCompleted = [GemEscapeData highestLevelNumberReached];
        
        //  array to hold all the level buttons created
        NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:numLevels];
        
        //  create level buttons, enabling only those levels that have been completed
        for (int i = 1; i <= numLevels; i++) {
            CCMenuItem *levelItem = [CCMenuItemFont itemWithString:[NSString stringWithFormat:@"level %d", i] block:^(id sender) {
                [[CCDirector sharedDirector] replaceScene:[GameScene sceneWithStartingLevelNumber:i]];
            }];
            if (i > highestLevelCompleted)
                [levelItem setIsEnabled:NO];
            
            //  add created button to arr
            [arr addObject:levelItem];
        }
        
        //  create the levels menu with a button for each menu and add to scene
        CCMenu *levelsMenu = [CCMenu menuWithArray:arr];
        [levelsMenu setPosition:ccp(size.width /2 , size.height/2)];
        [levelsMenu alignItemsVerticallyWithPadding:LEVELS_PADDING];
        [self addChild:levelsMenu];
        
        //  add back to menu button
        [CCMenuItemFont setFontSize:BACK_TEXT_SIZE];
        CCMenuItem *backItem = [CCMenuItemFont itemWithString:@"Back To Menu" block:^(id sender) {
            [[CCDirector sharedDirector] replaceScene:[MenuScene scene]];
        }];
        CCMenu *backMenu = [CCMenu menuWithItems:backItem, nil];
        [backMenu setPosition:ccp(size.width /2 , BACK_TEXT_SIZE)];
        [self addChild:backMenu];
    }
    
	return self;
}

@end
