//
//  MenuScene.h
//  GemEscape
//
//  This is the first scene of GemEscape, presents a menu to the user to select.
//
//  Created by Peter Lin on 26/04/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "GameKit/GameKit.h"
@interface MenuScene : CCLayer <GKLeaderboardViewControllerDelegate>
//  returns a CCScene that contains the GameScene as the only child. this method is required by cocos2d.
+(CCScene *) scene;
@end
