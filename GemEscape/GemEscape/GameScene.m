//
//  GameScene.m
//  GemEscape
//
//  This implements the GameScene.h.
//
//  Reference sources:
//  http://www.raywenderlich.com/352/how-to-make-a-simple-iphone-game-with-cocos2d-tutorial
//  http://stackoverflow.com/questions/6170110/cocos2d-fade-in-out-action-to-repeat-forever
//  https://developers.google.com/mobile-ads-sdk/docs/ios/fundamentals
//
//  Other icons and images as acknowledged on the loading screen. Significant knowledge was also gained
//  from CS193P available on iTunes U.
//  
//  Created by Peter Lin on 14/04/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//

#import "GameScene.h"
#import "GemEscapeData.h"
#import "AppDelegate.h"
#import "GemEscapeLevel.h"
#import "MenuScene.h"
#import "SelectLevelScene.h"
#import "GADBannerView.h"

//  defines if ads are diplayed. set this to true/false. YES/NO will not work. This affects if ads 
//  will be displayed, and the general UI layout will adjust accordingly to make best use of space available.
#define DISPLAY_ADS true

//  different constant offsets depending on wether ads are displayed or not
#if DISPLAY_ADS
#define TILES_Y_OFFSET 100          //  this is the offset of where the tiles map will begin
#define BUTTONS_Y_OFFSET 75         //  this is the offset of where the row of buttons are located
#define HEARTS_ROW_OFFSET 1         //  this is the row offset of where the hearts should be displayed
#else
#define TILES_Y_OFFSET 110          //  same as above, adjusted to make better use of increased space without ads
#define BUTTONS_Y_OFFSET 80
#define HEARTS_ROW_OFFSET 2
#endif

#define BACKGROUND_Y_OFFSET -15         //  to offset of background tiless for visual 2d alignment
#define SLIDE_ANIMATION_SECONDS 0.2     //  the seconds it takes for slide animation (this is the duration per block slide)
#define FADE_ANIMATION_SECONDS 0.5      //  the seconds it takes for fade in/out animation
#define ADMOB_ID @"a14f9f7adcadddd"     //  this is my ID for AdMob

#define PAUSE_LAYER_TAG 90000           //  this is the tag of the pause layer so it can be removed on resume
#define PAUSE_MENU_TAG 90001            //  this is the tag of the pause menu so it can be removed on resume

#define TITLE_LABEL_SIZE 50             //  this is the size of the title label/button text
#define LEVEL_LABEL_SIZE 25             //  this is the font size of the level label/button text
#define ICON_SPACING 20                 //  this is the spacing between the button icons
#define ICON_SIZE 40                    //  this is the size of the button icons

#define SPEECH_BUBBLE_X_OFFSET 50       //  this is the x offset of the speech bubbles for alignment
#define SPEECH_BUBBLE_TEXT_Y_OFFSET -10 //  this is the y offset of the text in speech bubbles for alignment
#define TIME_LABEL_X_POSITION 90        //  this is the x coord of the timer label
#define TIME_ICON_X_POSITION  30        //  this is the x coord of the timer icon

#define LEVEL_WIN_TEXT @"You Win!"              //  text shown if user beats a level
#define LEVEL_LOSE_TEXT @"You Lose!"            //  text shown if user loses a level
#define FINAL_LEVEL_WIN_TEXT @"Game Won!"       //  text shown if user beats all levels


//  various image files are defined here for easy editting and robustness
#define RESTART_IMAGE @"restart.png"
#define RESTART_SELECTED_IMAGE @"restart_selected.png"
#define RESTART_DISABLED_IMAGE @"restart_selected.png"
#define FF_IMAGE @"fast_forward.png"
#define FF_SELECTED_IMAGE @"fast_forward_selected.png"
#define FF_DISABLED_IMAGE @"fast_forward_selected.png"
#define PAUSE_IMAGE @"pause.png"
#define PAUSE_SELECTED_IMAGE @"pause_selected.png"
#define PAUSE_DISABLED_IMAGE @"pause_selected.png"
#define TIMER_IMAGE @"timer.png"
#define SPEECH_LEFT_IMAGE @"speech_bubble_left.png"
#define SPEECH_RIGHT_IMAGE @"speech_bubble_right.png"
#define POSITIVE_HEART_IMAGE @"heart.png"
#define NEGATIVE_HEART_IMAGE @"bug.png"
#define BACKGROUND_IMAGE @"stone_block.png"

#pragma mark - GameScene

@interface GameScene() <GemEscapeLevelDelegate, GADBannerViewDelegate>
//  this is the model of a gem escape level
@property (nonatomic, strong) GemEscapeLevel *level;                  

//  this is dictionary of CCSprite * displayed in the foreground, indexed by the sprites TileCoord
@property (nonatomic, strong) NSMutableDictionary *foregroundSprites;    

//  these are the X and Y offsets of where the tiles should begin
@property (nonatomic, assign) int tilesOffsetX;
@property (nonatomic, assign) int tilesOffsetY;

//  these are the widths and heights of the tiles
@property (nonatomic, assign) int tileWidth;
@property (nonatomic, assign) int tileHeight;

//  since each touch gesture has a begin and end, this records the starting TileCoord
@property (nonatomic, strong) TileCoord *touchStart;

//  this is a count of the total number of animations in progress
@property (assign) int animationsInProgress;

//  this is the CCLabelTTF used to display the number of seconds left
@property (nonatomic, weak) CCLabelTTF *timeLabel;

//  this is a BOOL to indicate if the game is currently paused
@property (nonatomic, assign) BOOL gameIsPaused;

//  this is a block to be executed if the game has ended. this block is used to force the user to 
//  wait for the animation to finish, since this block will be nil until the animations are done. 
@property (nonatomic, copy) void (^gameEndBlock)(void);

//  this is the timer icon that'll slowly disappear as time passes
@property (nonatomic, weak) CCProgressTimer *timerIcon;

//  this is number of hearts currently displayed
@property (atomic, assign) int numberOfHeartsDisplayed;

//  these are all the buttons are the game scene. these references are kept so the buttons can be
//  disabled and enabled as required
@property (nonatomic, weak) CCMenuItem *titleButton;
@property (nonatomic, weak) CCMenuItem *levelButton;
@property (nonatomic, weak) CCMenuItem *pauseButton;
@property (nonatomic, weak) CCMenuItem *fastForwardButton;
@property (nonatomic, weak) CCMenuItem *restartButton;

//  these are the view and view controller used by admob ads
@property (nonatomic, strong) GADBannerView *adMobBanner;
@property (nonatomic, strong) UIViewController *adMobViewController;
@end

// GameScene implementation
@implementation GameScene

@synthesize level = _level;
@synthesize tilesOffsetX = _tilesOffsetX;
@synthesize tilesOffsetY = _tilesOffsetY;
@synthesize tileWidth = _tileWidth;
@synthesize tileHeight = _tileHeight;
@synthesize foregroundSprites = _foregroundSprites;
@synthesize touchStart = _touchStart;
@synthesize animationsInProgress = _animationsInProgress;
@synthesize timeLabel = _timeLabel;
@synthesize gameIsPaused = _gameIsPaused;
@synthesize gameEndBlock = _gameEndBlock;
@synthesize timerIcon = _timerIcon;
@synthesize titleButton = _titleButton;
@synthesize levelButton = _levelButton;
@synthesize pauseButton = _pauseButton;
@synthesize fastForwardButton = _fastForwardButton;
@synthesize restartButton = _restartButton;
@synthesize numberOfHeartsDisplayed = _numberOfHeartsDisplayed;
@synthesize adMobBanner = _adMobBanner;
@synthesize adMobViewController = _adMobViewController;

#pragma mark - init / creation / setup methods

//  see GameScene.h
+(CCScene *) sceneWithStartingLevelNumber: (int) levelNumber
{
	CCScene *scene = [CCScene node];
	GameScene *layer = [GameScene nodeWithNewGameAtLevelNumber:levelNumber];
    [scene addChild: layer];
    return scene;
}

//  see GameScene.h
+(CCScene *) sceneByResumingLastGame 
{
    CCScene *scene = [CCScene node];
	GameScene *layer = [GameScene nodeWithResumedGame];
    [scene addChild: layer];
    return scene;
}

//  this creates a node for a new game at a level number specified
+(id) nodeWithNewGameAtLevelNumber: (int) levelNumber
{
    return  [[self alloc] initWithNewGameAtLevelNumber:levelNumber];
}

//  this creates a node for a previous game
+(id) nodeWithResumedGame
{
    return  [[self alloc] initWithResumedGame];
}

//  this inits a new game at the level number specific. uses the helper method startLevelAtLevelNumber
//  this also calls setup once to set up notifications and ads
- (id) initWithNewGameAtLevelNumber: (int) levelNumber
{
    if((self=[super init])) {
        [self startLevelAtLevelNumber:levelNumber];             // start level fresh
    }
    return self;
}

//  this also calls setup once to set up notifications and ads
-(id) initWithResumedGame
{
	if((self=[super init])) {
        self.level = [GemEscapeData savedLevelProgress];        // gets saved level
        [self setup];
        
    }
	return self;
}

//  this setup method is called when both starting a new level and resuming a game. it does the common setup,
//  such as calculating time width and offsets, displaying fixed content, dynamic content, and backgrounds. setting
//  the timer, and starting the level
- (void) setup
{
    // gets the display size and set tile size and offsets appropriately
    CGSize size = [[CCDirector sharedDirector] winSize];
    self.tileWidth = size.width / self.level.numberOfRows;
    self.tileHeight = self.tileWidth * 0.8;
    self.tilesOffsetX = self.tileWidth / 2;
    self.tilesOffsetY = size.height - TILES_Y_OFFSET - self.tileHeight / 2;
    
    //  register for did enter background, used for saving game progress and pausing game
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(enteredBackground) 
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    //  register for did become active, used for reloading ads
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(enteredForeground) 
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    //  clear the layer of any exiting images on screen
    [self removeAllChildrenWithCleanup:YES];
    
    //  create a new dict for foreground sprites
    self.foregroundSprites = [[NSMutableDictionary alloc] init];
    
    //  display fixed content, dynamic content, and the background tiles
    [self displayFixedContent];
    [self displayDynamicContent];
    [self displayBackground];
    
    //  set scheduler to update timer
    [self schedule:@selector(timerUpdate:)];
    
    //  set the variables to an appropriate initial state
    self.gameIsPaused = NO;
    self.gameEndBlock = nil;
    self.level.delegate = self;
    self.animationsInProgress = 0;
    self.numberOfHeartsDisplayed = 0;
    self.isTouchEnabled = YES;
    
    //  save the progress and start the level
    [self saveLevelProgress];
    [self.level startLevel];
    
    //  if level is finished, disable the fast forward button
    if (self.level.finished)
        self.fastForwardButton.isEnabled = NO;
    
    //  display ads if this is ad supported version
    if (DISPLAY_ADS)
        [self loadAd];
}

#pragma mark - pause/resume methods

//  this method allows the game to be paused
- (void) pauseLevel
{
    //  check if already paused, only one pause is needed. multiple calls to this method is possible if
    //  the app is backgrounded etc
    if (self.gameIsPaused)                 
        return;
    else
        self.gameIsPaused = YES;
    
    //  pause director to stop animations, and unschedule the timerUpdate so time stops
    [[CCDirector sharedDirector] pause];
    [self unschedule:@selector(timerUpdate:)];

    //  disable touch and all buttons on pause
    self.isTouchEnabled = NO;
    [self setAllButtonsToEnabled:NO];
    
    //  creates the layer and menu shown on pause, and they are added to the current scene
    CCLayerColor *pauseLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 220)];
    CCMenuItemFont *resume = [CCMenuItemFont itemWithString:@"Resume" block:^(id sender){
        [self resumeLevel];
    }];
    CCMenuItemFont *exit = [CCMenuItemFont itemWithString:@"Return to Main Menu" block:^(id sender){
        [[CCDirector sharedDirector] resume];
        [self changeScene:[MenuScene scene]];
    }];
    CGSize size = [[CCDirector sharedDirector] winSize];
    CCMenu *pauseMenu = [CCMenu menuWithItems:resume, exit, nil];
    [pauseMenu alignItemsVerticallyWithPadding:20];
    pauseMenu.position = ccp(size.width / 2, size.height / 2);
    
    //  these are added with the highest possible Z indexes to make sure they are always on top
    [self addChild:pauseLayer z: INT32_MAX - 1 tag:PAUSE_LAYER_TAG];
    [self addChild:pauseMenu z: INT32_MAX tag:PAUSE_MENU_TAG];
    
}

//  this method allows the game to be resumed
- (void) resumeLevel
{
    //  remove the layer and menu just added
    [self removeChildByTag:PAUSE_MENU_TAG cleanup:YES];
    [self removeChildByTag:PAUSE_LAYER_TAG cleanup:YES];
    
    //  enable touch and all buttons on resume
    self.isTouchEnabled = YES;
    [self setAllButtonsToEnabled:YES];
    
    //  if level was finished, disable fast forward button, otherwise schedule the timer update again
    if (self.level.finished)
        self.fastForwardButton.isEnabled = NO;
    else
        [self schedule:@selector(timerUpdate:)];
    
    //  resume the director for animations
    [[CCDirector sharedDirector] resume];
    
    self.gameIsPaused = NO;
}

//  this method sets the isEnabled property on all of the buttons to the BOOL given
- (void) setAllButtonsToEnabled: (BOOL) b
{
    self.titleButton.isEnabled = b;
    self.levelButton.isEnabled = b;
    self.pauseButton.isEnabled = b;
    self.fastForwardButton.isEnabled = b;
    self.restartButton.isEnabled = b;
}

#pragma mark - private game logic methods

//  this is a helper method to start a level at the given level number
- (void) startLevelAtLevelNumber: (int) levelNumber
{
    //  first unschedule the timer update because the setup method will schedule this
    [self unschedule:@selector(timerUpdate:)];
    
    //  create new level and set level number
    self.level = [[GemEscapeLevel alloc] init];
    self.level.number = levelNumber;

    [self setup];
}

//  this is called when the app is backgrounded.
- (void) enteredBackground
{
    //  the level is paused when backgrounded, and the progress is saved
    [self pauseLevel];
    [self saveLevelProgress];
}

//  this is called after the app enters foreground. 
- (void) enteredForeground
{
    //  ads are reloaded
    if (DISPLAY_ADS) {
        [self loadAd];
    }
    
    //  if the game is paused, pause the director so the animation is still paused, otherwise cocos2d
    //  automatically resumes animation
    if (self.gameIsPaused) {
        [[CCDirector sharedDirector] pause];
    }
}

//  this is called to save the level progress
- (void) saveLevelProgress
{
    //  progress is saved using the GemEscapeData
    [GemEscapeData setSavedLevelProgress:self.level];
}

//  this method is method by the scheduler, in here the timers should be updated.
-(void) timerUpdate: (ccTime) dt
{
    //  update the seconds left in the level model
    self.level.secondsLeft -= dt;
    
    //  if times up, unschedule the timer updates
    if (self.level.secondsLeft <= 0.0)
        [self unschedule:@selector(timerUpdate:)];
    
    //  update the seconds display and the progress icon
    int secondsLeft = self.level.secondsLeft;
    [self.timeLabel setString:[NSString stringWithFormat:@"%d:%02d", secondsLeft / 60, secondsLeft % 60]];
    self.timerIcon.percentage = self.level.secondsLeft / self.level.secondsAllowed * 100;
}

//  this method is used to change the scene to the scene given.
- (void) changeScene: (CCScene *) scene
{
    //  if displaying ads, we need to unload ads. only want ads to be visible during gameplay
    if (DISPLAY_ADS)
        [self unloadAd];

    // save game state, remove notification observer, and replace scene using CCDirector
    [self saveLevelProgress];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[CCDirector sharedDirector] replaceScene:scene];   // scenes are replaced to save memory
}

#pragma mark - private display helper methods

//  this method displays the contents that are fixed (don't depend on level)
- (void) displayFixedContent
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    // put title on top that returns to menu
    [CCMenuItemFont setFontSize:TITLE_LABEL_SIZE];
    self.titleButton = [CCMenuItemFont itemWithString:@"Gem Escape" block:^(id sender) {
        [self changeScene:[MenuScene scene]];
    }];
    CCMenu *menu = [CCMenu menuWithItems:self.titleButton, nil];
    [menu setPosition:ccp(size.width/2 - self.tileWidth, size.height - TITLE_LABEL_SIZE/2)];
    [self addChild:menu];
    
    // buttons to restart, fast forward, and pause
    self.restartButton = [CCMenuItemImage itemWithNormalImage:RESTART_IMAGE selectedImage:RESTART_SELECTED_IMAGE disabledImage:RESTART_DISABLED_IMAGE block:^(id sender) {
        [self startLevelAtLevelNumber:self.level.number];
    }];
    self.fastForwardButton = [CCMenuItemImage itemWithNormalImage:FF_IMAGE selectedImage:FF_SELECTED_IMAGE disabledImage:FF_DISABLED_IMAGE block:^(id sender) {
        if (! self.animationsInProgress) {
            [sender setIsEnabled:NO];
            [self pauseSchedulerAndActions];
            [self.level endLevel];
        }
    }];
    self.pauseButton = [CCMenuItemImage itemWithNormalImage:PAUSE_IMAGE selectedImage:PAUSE_SELECTED_IMAGE disabledImage:PAUSE_DISABLED_IMAGE block:^(id sender) {
        [self pauseLevel];
    }];
    CCMenu *buttonsMenu = [CCMenu menuWithItems:self.pauseButton, self.fastForwardButton, self.restartButton, nil];
    [buttonsMenu alignItemsHorizontallyWithPadding:10];
    [buttonsMenu setPosition:ccp(250, size.height - BUTTONS_Y_OFFSET)];
    [self addChild:buttonsMenu];
}

//  this method displays content that are dynamic (depends on state in the level)
- (void) displayDynamicContent
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    //  level button that displays current level, and allows user to go back to level selection scene
    [CCMenuItemFont setFontSize:LEVEL_LABEL_SIZE];
    self.levelButton = [CCMenuItemFont itemWithString:[NSString stringWithFormat:@"LVL %d", self.level.number] block:^(id sender) {
        [self changeScene:[SelectLevelScene scene]];
    }];
    CCMenu *levelMenu = [CCMenu menuWithItems:self.levelButton, nil];
    [levelMenu setPosition:ccp(size.width - self.tileWidth, size.height - TITLE_LABEL_SIZE / 2)];
    [self addChild:levelMenu];
    
    //  time label is left blank, the scheduled timer updates will set these properly
    self.timeLabel = [CCLabelTTF labelWithString:@"" fontName:@"Marker Felt" fontSize:32];
    self.timeLabel.position =  ccp(TIME_LABEL_X_POSITION , size.height - BUTTONS_Y_OFFSET);
    [self addChild: self.timeLabel];
    
    //  timer progress icon is added
    self.timerIcon = [CCProgressTimer progressWithSprite:[CCSprite spriteWithFile:TIMER_IMAGE]];
    self.timerIcon.type = kCCProgressTimerTypeRadial;
    self.timerIcon.reverseDirection = YES;
    self.timerIcon.percentage = 100;
    self.timerIcon.position = ccp (TIME_ICON_X_POSITION, size.height - BUTTONS_Y_OFFSET);
    [self addChild:self.timerIcon];
}

//  this method displays the background. currently only one background is supported, and it's entirely made out of stone blocks
- (void) displayBackground
{
    int nRows = self.level.numberOfRows;
    int nColumns = self.level.numberOfColumns;
    
    //  loop through all the tiles and display the background image
    for (int i = 0; i < nRows; i++) {
        for (int j = 0; j < nColumns; j++) {
            NSString *backgroundImage = BACKGROUND_IMAGE;
            CGPoint p = [self getPointPositionForTileCoords: [TileCoord coordWithRow:i AndColumn:j]];
            p.y += BACKGROUND_Y_OFFSET;         // take out background offset
            CCSprite *sprite = [CCSprite spriteWithFile:backgroundImage];
            sprite.position = p;
            [self addChild:sprite];
        }
    }
}

//  this method displays a speech bubble dialogue for an object an tile coord and adds the string inside the bubble
- (void) displayDialogueAtTileCoord: (TileCoord *) coord WithText: (NSString *) string
{
    //  determines if the bubble should be left direction or right direction based on tile coord
    BOOL onLeft = (coord.column <= self.level.numberOfColumns / 2);
    NSString *speechBubbleFile = onLeft ? SPEECH_LEFT_IMAGE : SPEECH_RIGHT_IMAGE;
    
    //  creates sprite for speech bubble and fades it in
    CCSprite *speech = [CCSprite spriteWithFile:speechBubbleFile];
    CGPoint position = [self getPointPositionForTileCoords:[TileCoord coordWithRow:coord.row - 1 AndColumn: coord.column]];
    position.x += (onLeft) ? SPEECH_BUBBLE_X_OFFSET : -SPEECH_BUBBLE_X_OFFSET;
    speech.position = position;
    speech.opacity = 0;
    [self fadeSprite:speech ToOpacity:255];
    [self addChild:speech z: 2000];
    
    //  creates the text label for the speech bubble and fades it in
    CCLabelTTF *label = [CCLabelTTF labelWithString:string fontName:@"Marker Felt" fontSize:20];
    label.color = ccBLACK;
    label.opacity = 0;
    [self fadeSprite:label ToOpacity:255];
    position.y += SPEECH_BUBBLE_TEXT_Y_OFFSET;
    label.position = position;
    [self addChild: label z: 2001];
}

//  this method returns the z index to use for an object at coords, the return z index guarantees the objects on the lower rows
//  have a higher z index to ensure the 2D look is consistent
- (int) zIndexForTileCoord: (TileCoord *) coord
{
    return coord.row * self.level.numberOfColumns + coord.column;
}

#pragma mark - private touch helper methods

//  given a CGPoint position, returns if the pos is in the tile map
//  simply checks the tile coord of that pos is within bounds
- (BOOL) touchIsInTileMap: (CGPoint) pos
{
    TileCoord *coord = [self getTileCoordsFromPointPosition:pos];
    return (coord.row >= 0 && coord.column >= 0 && coord.row < self.level.numberOfRows && coord.column < self.level.numberOfColumns);
}

//  converts the tile coords to a CGPoint
- (CGPoint) getPointPositionForTileCoords: (TileCoord *) coords
{
    return ccp(self.tilesOffsetX + coords.column * self.tileWidth, (int) self.tilesOffsetY - coords.row * self.tileHeight);
}

//  converts the CGPoint to tile coords
- (TileCoord *) getTileCoordsFromPointPosition: (CGPoint) pos
{
    int col = (pos.x) / self.tileWidth;
    int tmp = -(pos.y - self.tilesOffsetY + BACKGROUND_Y_OFFSET);
    
    if (tmp < 0)
        tmp -= self.tileHeight;
    int row =  tmp / self.tileHeight;
    
    return [TileCoord coordWithRow:row AndColumn:col];
}

//  this is used to register touch with the cocos2d director
-(void) registerWithTouchDispatcher
{
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self 
                                                     priority:0 swallowsTouches:YES];
}

//  this method is called by the director when the touch begins
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{   
    if (self.animationsInProgress > 0)          //  ignore touches when animations are in progress
        return NO;
    
    if (! self.level.finished) {        //  if level is not yet finished
        //  convert touch location to current coords and tile coords
        CGPoint touchLocation = [touch locationInView: [touch view]];		
        touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        TileCoord *tc = [self getTileCoordsFromPointPosition:touchLocation];
        
        //  if the touch is in tile map
        if ([self touchIsInTileMap:touchLocation]) {
            //  update the touch start variable to the tile coord of where this touch was at
            if (! self.touchStart || ! [GemEscapeLevel tilesAreConnectedAtTileCoord:self.touchStart AndTileCoord:tc])
                self.touchStart = tc;
        } 
        return YES;
    } else {
        //  if level is finished and there is a valid block to execute for game end, then execute it
        if (self.gameEndBlock) {
            self.gameEndBlock();
        }
    }
    //  otherwise just returns NO
    return NO;
}

//  this method is called by the director when the touch finishes
-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (self.animationsInProgress > 0)          //  ignore touches when animations are in progress
        return;
    
    if (! self.level.finished) {            // only care about touch ends if level isn't finished
        //  convert touch location to current coords and tile coords
        CGPoint touchLocation = [touch locationInView: [touch view]];		
        touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        TileCoord *touchEnd = [self getTileCoordsFromPointPosition:touchLocation];
        
        //  every touch end should have a valid touch start
        if (self.touchStart) {
            //  don't do anything if touch start is the same as touch end
            if (! [self.touchStart isEqual:touchEnd]) {
                // do some user friendliness here by getting general direction
                if (self.touchStart.row == touchEnd.row) {
                    if (touchEnd.column < self.touchStart.column)
                        touchEnd.column = self.touchStart.column - 1;
                    else 
                        touchEnd.column = self.touchStart.column + 1;
                } else if (self.touchStart.column == touchEnd.column) {
                    if (touchEnd.row < self.touchStart.row)
                        touchEnd.row = self.touchStart.row - 1;
                    else
                        touchEnd.row = self.touchStart.row + 1;
                }
                
                //  if touch end is in tile map, the try to swap the tiles at touch start and touch end
                if ([self touchIsInTileMap:[self getPointPositionForTileCoords:touchEnd]]) {
                    [self swapTileAtTileCoord:self.touchStart WithTileAtTileCoord:touchEnd];
                }
                
                //  finished gesture, touch start is set to nil
                self.touchStart = nil;
            }
        }
    }
}

#pragma mark - private animation helper methods

//  this method finds the longest move in terms of rows for all the moves from coords to to coords
//  this is useful for determining which moves would take the longest time, and delay callbacks accordingly
- (int) findLongestMoveRowsForObjectsAtTileCoord: (NSArray *) fromCoords ToTileCoord: (NSArray *) toCoords
{
    int rows = 0;
    // simply loops through all the moves, and records the move with the largest row difference
    for (int i = 0, n = [fromCoords count]; i < n; i++) {
        TileCoord *fromCoord = [fromCoords objectAtIndex:i];
        TileCoord *toCoord = [toCoords objectAtIndex:i];
        if (toCoord.row - fromCoord.row > rows)
            rows = toCoord.row - fromCoord.row;
    }
    return rows;
}

//  this method fades the given sprite to the opacity given
- (void) fadeSprite: (CCSprite *) sprite ToOpacity: (int) o
{
    if (o < 0) o = 0;
    if (0 > 255) o = 255;
    id actionFade = [CCFadeTo actionWithDuration:FADE_ANIMATION_SECONDS opacity:o];
    [sprite runAction:actionFade];
}

//  this method moves a sprite to the tile coord in the number of seconds specified, and when done, executes the callback block
//  the callback block can be nil if there should be no callback
- (void) moveSprite: (CCSprite *) sprite 
        ToTileCoord: (TileCoord *) coord 
InDurationInSeconds: (float) seconds 
  ThenCallbackBlock: (void (^)(void)) callbackBlock
{
    //  the move action
    id actionMove = [CCMoveTo actionWithDuration:seconds 
                                        position:[self getPointPositionForTileCoords:coord]];
    if (callbackBlock) {
        //  if there is a non-nil callback block, also create a callback actionm and execute the sequence on sprite
        id actionMoveDone = [CCCallBlock actionWithBlock:callbackBlock];
        [sprite runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
    } else {
        //  no callback block, so just run the move action
        [sprite runAction:actionMove];
    }
    
    //  sets the sprite to the correct z index
    [sprite setZOrder:[self zIndexForTileCoord:coord]];
}

//  this method attempts to swap the tile at coord c1 with the tile at coord c2
- (void) swapTileAtTileCoord: (TileCoord *) c1 WithTileAtTileCoord: (TileCoord *) c2
{
    //  the tiles need to be connected for the swap to happen
    if ([[self.level class] tilesAreConnectedAtTileCoord:c1 AndTileCoord:c2]) {
        //  get the sprites that will be swapped
        CCSprite *s1 = [self.foregroundSprites objectForKey:c1];
        CCSprite *s2 = [self.foregroundSprites objectForKey:c2];
        
        if ([self.level objectsAreSwappableAtTileCoord:c1 AndTileCoord:c2]) {
            //  if the objects are swappable, then execute oridinary swap
            [self.level swapTileAtTileCoord:c1 WithTileAtTileCoord:c2];
            [self.foregroundSprites setObject:s1 forKey:c2];
            [self.foregroundSprites setObject:s2 forKey:c1];            
            
            //  swap the sprites using the move animation 
            self.animationsInProgress+=2;
            [self moveSprite:s1 ToTileCoord:c2 InDurationInSeconds:SLIDE_ANIMATION_SECONDS ThenCallbackBlock:^{
                self.animationsInProgress--;
            }];
            [self moveSprite:s2 ToTileCoord:c1 InDurationInSeconds:SLIDE_ANIMATION_SECONDS ThenCallbackBlock:^{
                self.animationsInProgress--;
            }];
        } else {
            //  objects are not swappable, then execute swap with a callback to reverse the swap
            self.animationsInProgress += 3;
            
            //  swap the sprites using the move animation 
            [self moveSprite:s1 ToTileCoord:c2 InDurationInSeconds:SLIDE_ANIMATION_SECONDS ThenCallbackBlock:^{
                self.animationsInProgress--;
            }];
            [self moveSprite:s2 
                 ToTileCoord:c1 
         InDurationInSeconds:SLIDE_ANIMATION_SECONDS 
           ThenCallbackBlock:^{
               //   callback to reverse swap here
               [self.foregroundSprites setObject:s1 forKey:c1];
               [self.foregroundSprites setObject:s2 forKey:c2];
               
               //  reverse swap the sprites using the move animation 
               [self moveSprite:s1 ToTileCoord:c1 InDurationInSeconds:SLIDE_ANIMATION_SECONDS ThenCallbackBlock:^{
                   self.animationsInProgress--;
               }];
               [self moveSprite:s2 ToTileCoord:c2 InDurationInSeconds:SLIDE_ANIMATION_SECONDS ThenCallbackBlock:^{
                   self.animationsInProgress--;
               }];
           }];
        }
    }
}

//  this method fades out and removes a sprite and then executes the callback Block after the animation and delete is complete
- (void) fadeOutAndRemoveSprite: (CCSprite *) sprite ThenCallBlock: (void (^)(void)) callbackBlock
{
    //  action to fade out the sprite
    id actionFade = [CCFadeTo actionWithDuration:FADE_ANIMATION_SECONDS opacity:0.0f];
    
    //  action to remove the sprite after fade out is done
    id actionFadeDone = [CCCallBlockN actionWithBlock:^(CCNode *node) {
        [self removeChild:node cleanup:YES];
    }];        
    CCSequence *sequence;
    
    //  if there is a valid callback block, add callback block to sequence
    if (callbackBlock) {
        id actionLastFade = [CCCallBlock actionWithBlock:callbackBlock];
        sequence = [CCSequence actions:actionFade, actionFadeDone, actionLastFade, nil];
    } else {
         sequence = [CCSequence actions:actionFade, actionFadeDone, nil];
    }
    
    //  run the action sequence on the sprite
    [sprite runAction:sequence];
}


#pragma mark - GemEscapeLevelDelegate

//  see GemEscapeLevelDelegate in GemEscapeLevel.h
- (void) levelEndedWithGameWon: (BOOL) won
{
    //  determine the text to display
    NSString *text = won ? LEVEL_WIN_TEXT : LEVEL_LOSE_TEXT;
    BOOL finishedFinalLevel = self.level.number == [[GemEscapeData levelsData] count];
    if (won && finishedFinalLevel)
        text = FINAL_LEVEL_WIN_TEXT;
    
    //  try to find a remaining human to attach the speech bubble
    TileCoord *humanCoord = [self.level getTileCoordOfAnyObjectOfType:HUMAN];
    
    //  if no humans left, then randomly create a human somewhere
    if (! humanCoord) {
        while (YES) {
            humanCoord = [TileCoord coordWithRow:arc4random() % self.level.numberOfRows 
                                       AndColumn:arc4random() % self.level.numberOfColumns];
            
            if ([self.foregroundSprites objectForKey:humanCoord] == nil)
                break;
        }
        [self newForegroundObject:[GemEscapeData getRandomForegroundObjectOfType:HUMAN] 
               CreatedAtTileCoord:humanCoord 
                DropsToTileCoords:humanCoord];
    }
    
    //  display the dialogue for the human with the text
    [self displayDialogueAtTileCoord:humanCoord WithText:text];
    
    //  if the user has won and this is not the final level
    if (won && ! finishedFinalLevel) {
        //  check if this is the player's highest level reach, if so update the highest level reached
        if (self.level.number + 1 > [GemEscapeData highestLevelNumberReached])
            [GemEscapeData setHighestLevelNumberReachedTo:self.level.number + 1];

        //  set the gameEndBlock to start a new level at a higher level number
        __block GameScene *game = self;
        self.gameEndBlock = ^{
            [game startLevelAtLevelNumber: self.level.number + 1];
        };
    } else {
        //  player didn't win or has reached final level, restart current level for game end block
        __block GameScene *game = self;
        self.gameEndBlock = ^{
            [game startLevelAtLevelNumber: self.level.number];
        };
    }
}

//  see GemEscapeLevelDelegate in GemEscapeLevel.h
- (void) updateHearts
{
    //  updates the number of hearts displayed using the pushHeartOnDisplayByIncreasing method
    int numHearts = self.level.numberOfHeartsLeft;
    while (self.numberOfHeartsDisplayed < numHearts) {
        [self pushHeartOnDisplayByIncreasing:YES];
        self.numberOfHeartsDisplayed++;
    }
    
    while (self.numberOfHeartsDisplayed > numHearts) {
       [self pushHeartOnDisplayByIncreasing:NO];
        self.numberOfHeartsDisplayed--;
    }
}

//  this method "pushes" and "pops" hearts onto the display, and basically updates the hearts shown
- (void) pushHeartOnDisplayByIncreasing: (BOOL) isIncrease
{
    //  this static array keeps the reference of the heart sprites shown, makes it possible to remove them
    static NSMutableArray *arr = nil;
    
    //  alloc array if it is nil, or if there are no hearts on display, clear the references
    if (! arr || self.numberOfHeartsDisplayed == 0) {
        arr = [[NSMutableArray alloc] init];
    }
    
    if ((self.numberOfHeartsDisplayed <= 0 && !isIncrease) || (self.numberOfHeartsDisplayed >= 0 && isIncrease)) {
        //  if we're decreasing negative hearts, or increasing positive hearts, we are adding a sprite onto the display

        //  the spirte image used depends on wether it's positive or negative
        NSString *imageFile = isIncrease ? POSITIVE_HEART_IMAGE : NEGATIVE_HEART_IMAGE;
        
        // increase hearts on display by adding a new sprite
        CCSprite *heart = [CCSprite spriteWithFile:imageFile];
        heart.opacity = 0;
        heart.position = [self getPointPositionForTileCoords:[TileCoord coordWithRow:self.level.numberOfRows + HEARTS_ROW_OFFSET 
                                                                           AndColumn:self.level.numberOfColumns - abs(self.numberOfHeartsDisplayed) -1]
                          ];
        [self addChild:heart];
        [self fadeSprite:heart ToOpacity:255];
        //  add sprite to array to keep reference
        [arr addObject:heart];
    } else {
        //  otherwise, we are removing sprites. get the last sprite added to array, and remove it from scene and array
        int indexToRemove = [arr count] - 1;
        id objToRemove = [arr objectAtIndex:indexToRemove];
        [arr removeObjectAtIndex:indexToRemove];
        [self removeChild:objToRemove cleanup:YES];
    }    
}

//  see GemEscapeLevelDelegate in GemEscapeLevel.h
- (void) objectsShouldDisappearAtTileCoords: (NSSet *) coords 
                              ThenCallBlock: (void (^)(void)) callbackBlock
{
    int numLeft = [coords count];
    
    //  loops through all the objects that should disappear and fade out and remove them all
    for (TileCoord *coord in coords) {
        CCSprite *sprite = [self.foregroundSprites objectForKey:coord];
        
        id callback = nil;
        if ((--numLeft) == 0 && callbackBlock) {
            //  on the last object to fade out and remove, attach the callback Block if it is non-nil
            callback = callbackBlock;
        } 
        [self fadeOutAndRemoveSprite:sprite ThenCallBlock:callback];
        [self.foregroundSprites removeObjectForKey:coord];
    }
}

//  see GemEscapeLevelDelegate in GemEscapeLevel.h
- (void) moveObjectsAtTileCoord: (NSArray *) fromCoords 
                    ToTileCoord: (NSArray *) toCoords 
                  ThenCallBlock: (void (^)(void)) callbackBlock;
{
    //  the from coords count and to coords count must always match
    if ([fromCoords count] != [toCoords count]) {
        NSLog(@"GameScene fromCoords count does not match toCoords count");
        return;
    }
    //  BOOL is used to make sure callback block is only attached to one move animation
    BOOL calledBack = NO;
    int longestMoveRows;
    
    //  if there is a valid callback block, find the longest move in terms of rows
    //  this is used to determine which move to attach the callback to, since the larger the move the longer the duration
    if (callbackBlock)
        longestMoveRows = [self findLongestMoveRowsForObjectsAtTileCoord:fromCoords ToTileCoord:toCoords];

    for (int i = 0, n = [fromCoords count]; i < n; i++) {
        TileCoord *fromCoord = [fromCoords objectAtIndex:i];
        TileCoord *toCoord = [toCoords objectAtIndex:i];
        
        //  the sprite to be moved
        CCSprite *sprite = [self.foregroundSprites objectForKey: fromCoord];
        
        id callback = nil;
        
        //  attach callback block once on the move with the longest move rows (since it has highest duration)
        if (callbackBlock && (toCoord.row - fromCoord.row) == longestMoveRows && ! calledBack) {
            callback = callbackBlock;
            calledBack = YES;
        } 
        
        //  update the key of the moved object
        [self.foregroundSprites setObject:[self.foregroundSprites objectForKey:fromCoord] forKey:toCoord];
        [self.foregroundSprites removeObjectForKey:fromCoord];
        
        //  run the move animation, with the callback block
        [self moveSprite:sprite 
             ToTileCoord:toCoord 
     InDurationInSeconds:(toCoord.row - fromCoord.row) * SLIDE_ANIMATION_SECONDS 
       ThenCallbackBlock:callback];
    }
}

//  see GemEscapeLevelDelegate in GemEscapeLevel.h
- (void) newForegroundObject: (ForegroundObject *) obj 
          CreatedAtTileCoord: (TileCoord *) createCoord 
           DropsToTileCoords: (TileCoord *) finalCoord
{
    // creates a new sprite for the image file 
    CCSprite *sprite = [CCSprite spriteWithFile:obj.imageFilename];
    sprite.position = [self getPointPositionForTileCoords:createCoord];
    sprite.opacity = 0;
    
    //  fade it in and do the move animation
    [self fadeSprite:sprite ToOpacity:255];
    self.animationsInProgress++;
    [self moveSprite:sprite 
         ToTileCoord:finalCoord 
 InDurationInSeconds:(finalCoord.row - createCoord.row) * SLIDE_ANIMATION_SECONDS ThenCallbackBlock:^{
     self.animationsInProgress--;
 }];
    [self.foregroundSprites setObject:sprite forKey:finalCoord];
    //  sets the z index 
    [self addChild:sprite  z:[self zIndexForTileCoord:finalCoord]];
}

#pragma mark - ad methods / GADBannerViewDelegate

//  see GADBannerViewDelegate
- (void)adViewWillPresentScreen:(GADBannerView *)bannerView
{
    //  this is called if the user clicks on an ad, we pause the level to user can continue when they return
    [self pauseLevel];
}

//  this is called to load an ad
- (void) loadAd 
{
    //  create banner if not exists
    if (! self.adMobBanner) {
        CGSize size = [[CCDirector sharedDirector] winSize];
        self.adMobBanner = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
        self.adMobBanner.adUnitID = ADMOB_ID;
        self.adMobBanner.delegate = self;
        CGSize adSize = CGSizeFromGADAdSize(kGADAdSizeBanner);
        self.adMobBanner.frame = CGRectMake(0, size.height - adSize.height, adSize.width, adSize.height);
    }
    
    //  create ad view controller if not exists
    if (! self.adMobViewController) {
        self.adMobViewController = [[UIViewController alloc] init];
        self.adMobViewController.view = [[CCDirector sharedDirector] view];
        self.adMobBanner.rootViewController = self.adMobViewController;
        [self.adMobViewController.view addSubview:self.adMobBanner];
    }
    
    //  request a new ad
    GADRequest *adRequest = [GADRequest request];
    adRequest.testing = YES;                            //  this is for testing only, remove for production
    [self.adMobBanner loadRequest:adRequest];
}

//  this is called to unload an ad
- (void) unloadAd
{
    [self.adMobBanner removeFromSuperview];
    self.adMobBanner = nil;
    self.adMobBanner.delegate = nil;
    self.adMobViewController = nil;
}
@end
