//
//  GemEscapeModel.h
//  GemEscape
//
//  This is the model of a level. It contains both the data and the logic of the game. It specifies a 
//  GemEscapeLevelDelegate protocol that the view controller delegate should implement. The displays are done
//  through calls to the delegate.
//
//  Created by Peter Lin on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TileCoord.h"
#import "ForegroundObject.h"

@protocol GemEscapeLevelDelegate
//  NOTE: the significant use of callback blocks allow the level to chain events as it wishes
//  all of the methods are required, other the display probably won't make sense
@required

//  the objects should disappear at the tile coords given. after the objects have disappeared, execute the callback Block
//  the callback Block can be nil if there is nothing more to execute
- (void) objectsShouldDisappearAtTileCoords: (NSSet *) coords ThenCallBlock: (void (^)(void)) callbackBlock;

//  the objects at the from coords should be moved to the to coords. after the move is complete, the callback Block should be executed
//  the callback Block can be nil if there is nothing to execute
- (void) moveObjectsAtTileCoord: (NSArray *) fromCoord ToTileCoord: (NSArray *) toCoord ThenCallBlock: (void (^)(void)) callbackBlock;

//  a new foreground object has BEEN created at createCoord and it should drop the the dropCoord. the coords can be used for animation if there
//  are any, otherwise just display the obj at the dropCoord
- (void) newForegroundObject: (ForegroundObject *) obj CreatedAtTileCoord: (TileCoord *) createCoord DropsToTileCoords: (TileCoord *) dropCoord;

//  the number of hearts has been updated
- (void) updateHearts;

//  the level has ended with the game won (YES/NO)
- (void) levelEndedWithGameWon: (BOOL) won;
@end

@interface GemEscapeLevel : NSObject <NSCoding>
//  the number of rows and columns
@property (nonatomic, readonly) int numberOfRows;
@property (nonatomic, readonly) int numberOfColumns;

//  the view controller delegate that coordinates the display
@property (nonatomic, weak) id <GemEscapeLevelDelegate> delegate;

//  this level's number
@property (nonatomic, assign) int number;

//  the number of hearts left
@property (nonatomic, assign) int numberOfHeartsLeft;

//  the number of seconds left
@property (nonatomic, assign) float secondsLeft;

//  the total number of seconds allowed for this level
@property (nonatomic, assign) float secondsAllowed;

//  the BOOL that this level is finished
@property (nonatomic, assign) BOOL finished;

#pragma mark - methods

//  starts the level. this method is called for both new levels and resuming levels. 
- (void) startLevel;

//  ends the level. it can be called before times up, but it will be called automatically when the times up
- (void) endLevel;

//  swap tiles at the tile coords in the model
- (void) swapTileAtTileCoord: (TileCoord *) c1 WithTileAtTileCoord: (TileCoord *) c2;

//  determines if the two tile coords are directly connected
+ (BOOL) tilesAreConnectedAtTileCoord: (TileCoord *) c1 AndTileCoord: (TileCoord *) c2;

//  returns the TileCoord of any object of type in the entire tile map
- (TileCoord *) getTileCoordOfAnyObjectOfType: (foreground_object_t) type;

//  returns true if the objects at tile coords are connected and both are swappable
- (BOOL) objectsAreSwappableAtTileCoord: (TileCoord *) c1 AndTileCoord: (TileCoord *) c2;

@end
