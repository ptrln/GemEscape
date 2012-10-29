//
//  HowToPlayScene.m
//  GemEscape
//
//  Implements HowToPlayScene.h
//
//  Created by Peter Lin on 26/04/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "HowToPlayScene.h"

@implementation HowToPlayScene

#define TITLE_FONT_SIZE 32      //  font size of the "How To Play" title
#define BACK_FONT_SIZE 25       //  font size of the "Back To Menu" menu item

//  Helper class method that creates a Scene with the GemEscapeLayer as the only child.
+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
    HowToPlayScene *layer = [HowToPlayScene node];
    [scene addChild: layer];
    return scene;
}

//  on "init" you need to initialize your instance
-(id) init
{
	//  always call "super" init
	//  Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init])) {
        CGSize size = [[CCDirector sharedDirector] winSize];

        //  display the how to play art and add to scene
        CCSprite *sprite = [CCSprite spriteWithFile:@"how_to_play.png"];
        sprite.position = ccp(size.width / 2, size.height / 2);
        [self addChild:sprite];
        
		//  create and initialize the how to play title
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"How To Play" fontName:@"Marker Felt" fontSize:TITLE_FONT_SIZE];
		label.position =  ccp( size.width /2, size.height - TITLE_FONT_SIZE);
		[self addChild: label];
        
        //  add back to menu item
        [CCMenuItemFont setFontSize:BACK_FONT_SIZE];
        CCMenuItem *backItem = [CCMenuItemFont itemWithString:@"Back To Menu" block:^(id sender) {
            [[CCDirector sharedDirector] popScene];
        }];
        CCMenu *backMenu = [CCMenu menuWithItems:backItem, nil];
        [backMenu setPosition:ccp(size.width /2, BACK_FONT_SIZE)];
        [self addChild:backMenu];
    }
	return self;
}

@end
