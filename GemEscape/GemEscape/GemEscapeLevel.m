//
//  GemEscapeModel.m
//  GemEscape
//
//  Implements GemEscapeModel.h
//
//  Created by Peter Lin on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GemEscapeLevel.h"
#import "GemEscapeData.h"

//  defines the number of gems to form a line. 3 means a minimum of 3 is required.
#define GEM_LINE_QUANTITY 3

//  the number of rows and columns. this is defined as a constant as all of the levels use the same number of rows and columns
//  the level itself is flexible to any size, so in the future if this changes then just load it as one of the params
#define NUMBER_OF_ROWS 8            
#define NUMBER_OF_COLUMNS 8 

//  various keys used for encoding/decoding
#define LEVEL_NUMBER_ENCODER_KEY @"LEVEL_NUMBER_ENCODER"
#define FOREGROUND_OBJECTS_ENCODER_KEY @"FOREGROUND_OBJS_ENCODER"
#define SECONDS_LEFT_ENCODER_KEY @"SECONDS_LEFT_ENCODER"
#define SECONDS_ALLOWED_ENCODER_KEY @"SECONDS_ALLOWED_ENCODER"
#define NUM_HEARTS_LEFT_ENCODER_KEY @"NUM_HEARTS_LEFT_ENCODER"
#define LEVEL_FINISHED_ENCODER_KEY @"LEVEL_FINISHED_ENCODER"

@interface GemEscapeLevel()
//  the dictionary holds the ForegroundObject in the tile map indexed by TileCoord
//  because of the way the ForegroundObjects are designed, there is only one instance per ForegroundObject,
//  so multiple objects of the same type actually point to the same thing, this is useful for fast comparisons
@property (nonatomic, strong) NSMutableDictionary *foregroundObjects;
@end

@implementation GemEscapeLevel

@synthesize delegate = _delegate;
@synthesize foregroundObjects = _foregroundObjects;
@synthesize number = _number;
@synthesize numberOfHeartsLeft = _numberOfHeartsLeft;
@synthesize secondsLeft = _secondsLeft;
@synthesize secondsAllowed = _secondsAllowed;
@synthesize finished = _finished;

#pragma mark - public methods

//  see GemEscapeModel.h
- (void) startLevel
{
    self.finished = NO;
    
    //  check if this is a resumed game or a new one, resumed one will have foreground objects already
    if (self.foregroundObjects) {
        //  put all of the non-nil objects back in display using the delegate
        for (int i = self.numberOfRows - 1; i >= 0 ; i--) {
            for (int j = self.numberOfColumns - 1; j >= 0 ; j--) {
                TileCoord *tc = [TileCoord coordWithRow:i AndColumn:j];
                ForegroundObject *obj = [self.foregroundObjects objectForKey:tc];
                if (obj)
                    [self.delegate newForegroundObject:obj CreatedAtTileCoord:[TileCoord coordWithRow:i - 1 AndColumn:j] DropsToTileCoords:tc];
            }
        }
        //  if some foreground objs are gone, it means game was in progress of ending or has ended, so initiate end game sequence
        if ([self.foregroundObjects count] != self.numberOfRows * self.numberOfColumns)
            [self endLevel];
    } else {
        //  there are no existing foreground objects, this is a new game
        
        //  load all required level data using GemEscapeData
        NSDictionary *levelData = [[GemEscapeData levelsData] objectForKey:[NSString stringWithFormat:@"%d", self.number]];
        int numStars = 0;
        int maxNumberOfStars = [[levelData objectForKey:@"max_number_star"] intValue];
        int chanceOfStarObject = [[levelData objectForKey:@"star_obj_chance"] intValue];
        int chanceOfHurtfulObject = [[levelData objectForKey:@"hurtful_obj_chance"] intValue];
        int chanceOfBlockObject = [[levelData objectForKey:@"block_obj_chance"] intValue];
        int chanceOfHumanObject = [[levelData objectForKey:@"human_obj_chance"] intValue];
        int chanceOfBonusHeart = [[levelData objectForKey:@"heart_bonus_chance"] intValue];
        int numberOfGemColorVariations = [[levelData objectForKey:@"gem_color_variations"] intValue];
        self.numberOfHeartsLeft = [[levelData objectForKey:@"num_starting_hearts"] intValue];
        self.secondsAllowed = self.secondsLeft = [[levelData objectForKey:@"duration_seconds"] floatValue];
        
        //  alloc and init foreground objs dictionary
        self.foregroundObjects = [[NSMutableDictionary alloc] initWithCapacity:self.numberOfRows * self.numberOfColumns];
        
        for (int i = self.numberOfRows - 1; i >= 0 ; i--) {
            for (int j = self.numberOfColumns - 1; j >= 0 ; j--) {
                
                //  create a foreground obj for each tile in tile map using the probabilities specified in the level data
                ForegroundObject *obj;
                if (numStars < maxNumberOfStars && (arc4random() % 100) < chanceOfStarObject) {
                    obj = [GemEscapeData getRandomForegroundObjectOfType:STAR];
                    numStars++;
                } else if ((arc4random() % 100) < chanceOfHurtfulObject) {
                    obj = [GemEscapeData getRandomForegroundObjectOfType:ENEMY];
                } else if (arc4random() % 100 < chanceOfHumanObject) {
                    obj = [GemEscapeData getRandomForegroundObjectOfType:HUMAN];
                } else if (arc4random() % 100 < chanceOfBonusHeart) {
                    obj = [GemEscapeData getRandomForegroundObjectOfType:HEART];
                } else if (arc4random() % 100 < chanceOfBlockObject) {
                    obj = [GemEscapeData getRandomForegroundObjectOfType:BLOCK];
                } else {
                    obj = [GemEscapeData getRandomForegroundGemObjectWithPoolSizeOf:numberOfGemColorVariations];
                }
                TileCoord *tc = [TileCoord coordWithRow:i AndColumn:j];
                
                //  add obj to foreground objects, and tell delegate a new obj has been created
                [self.foregroundObjects setObject:obj forKey:tc];
                [self.delegate newForegroundObject:obj CreatedAtTileCoord:[TileCoord coordWithRow:0 AndColumn:j] DropsToTileCoords:tc];
            }
        }
    }
    
    //  tell the delegate to update the hearts display
    [self.delegate updateHearts];
}

//  see GemEscapeModel.h
- (void) endLevel
{
    //  endLevel should only be called once
    if (self.finished)
        return;
    else
        self.finished = YES;
    
    //  find all of the STAR objects and GEM objects that are in line, and add them to remove set
    NSMutableSet *removeSet = [[NSMutableSet alloc] init];
    
    for (int i = self.numberOfRows - 1; i >= 0 ; i--) {
        for (int j = self.numberOfColumns - 1; j >= 0 ; j--) {
            TileCoord *tc = [TileCoord coordWithRow:i AndColumn:j];
            ForegroundObject *obj = [self.foregroundObjects objectForKey:tc];
            if (obj) {
                if (obj.type == GEM) {
                    for (id o in [self setOfObjectsThatMatchObject:obj AndAreInLineAtTileCoord:tc])
                        [removeSet addObject:o];
                } else if (obj.type == STAR) {
                    [removeSet addObject:tc];
                }
            }
        }
    }
    
    //  remove all of the STAR and in line GEM objects from foreground objects
    for (TileCoord *tc in removeSet)
        [self.foregroundObjects removeObjectForKey:tc];
    
    //  then ask the delegate to remove the objs, then callback callbackBlockToMoveObjects
    if ([removeSet count] > 0) {
        [self.delegate objectsShouldDisappearAtTileCoords:removeSet ThenCallBlock:[self callbackBlockToMoveObjects]];   
    } else {
        [self callbackBlockToMoveObjects]();
    }
}

//  see GemEscapeModel.h
- (TileCoord *) getTileCoordOfAnyObjectOfType: (foreground_object_t) type
{
    if ([self numberOfObjectsLeftOfType:type] == 0) {
        return nil;
    } else {
        while (YES) {
            //  try to get the obj from random row, continue until the row is found
            //  trying to make results more random
            int row = arc4random() % self.numberOfRows;
            NSSet *set = [self setOfObjectsOfType:type InRowNumber:row];
            if ([set count] > 0) {
                return [set anyObject];
            }
        }
    }
}

//  see GemEscapeModel.h
- (void) swapTileAtTileCoord: (TileCoord *) c1 WithTileAtTileCoord: (TileCoord *) c2
{
    if ([GemEscapeLevel tilesAreConnectedAtTileCoord:c1 AndTileCoord:c2]) {        
        id tmp1 = [self.foregroundObjects objectForKey:c1];
        id tmp2 = [self.foregroundObjects objectForKey:c2];
        [self.foregroundObjects setObject:tmp1 forKey:c2];
        [self.foregroundObjects setObject:tmp2 forKey:c1];
    }
}

//  see GemEscapeModel.h
+ (BOOL) tilesAreConnectedAtTileCoord: (TileCoord *) c1 AndTileCoord: (TileCoord *) c2
{
    //  tiles are connected if their row difference is 1 or column difference is 1
    if ((abs(c1.row - c2.row) == 1 && c1.column == c2.column) || 
        (abs(c1.column - c2.column) == 1 && c1.row == c2.row)) {
        return YES;
    }
    return NO;
}

//  see GemEscapeModel.h
- (BOOL) objectIsSwappableAtTileCoord: (TileCoord *) coord
{
    return [[self.foregroundObjects objectForKey:coord] swappable];
}

//  see GemEscapeModel.h
- (BOOL) objectsAreSwappableAtTileCoord: (TileCoord *) c1 AndTileCoord: (TileCoord *) c2
{
    if ([[self class] tilesAreConnectedAtTileCoord:c1 AndTileCoord:c2]) {
        ForegroundObject *obj1 = [self.foregroundObjects objectForKey:c1];
        ForegroundObject *obj2 = [self.foregroundObjects objectForKey:c2];
        
        return (obj1.type == STAR || obj2.type == STAR || (obj1.swappable && obj2.swappable));        
    }
    return NO;
}


#pragma mark - private methods

// returns the callback block to remove objects of type HEART, ENEMY, and HUMAN from the bottom row
- (void (^)(void)) callbackBlockToRemoveObjects
{
    return ^{
        //  only remove objs from the bottom row
        int row = self.numberOfRows - 1;
        NSSet *removeSet;
        
        //  the objs are removed in order, the HEART objs are always removed first, then the ENEMY objs
        //  only if there are no HEART or ENEMY objs, then the HUMAN objs will be removed
        if ([(removeSet = [self setOfObjectsOfType:HEART InRowNumber:row]) count] > 0) {
            //  incr hearts if there were any
            self.numberOfHeartsLeft += [removeSet count];
            [self.delegate updateHearts];
        } else if ([(removeSet = [self setOfObjectsOfType:ENEMY InRowNumber:row]) count] > 0) {
            //  decr hearts if there were any bugs
            self.numberOfHeartsLeft -= [removeSet count];
            [self.delegate updateHearts];
        } else { 
            removeSet = [self setOfObjectsOfType:HUMAN InRowNumber:row];        
        } 
        
        //  remove objs from the the foreground objs
        for (TileCoord *tc in removeSet)
            [self.foregroundObjects removeObjectForKey:tc];
        
        if ([removeSet count] == 0) {
            //  if no objs are removed, then we can call the final end game block
            [self.delegate levelEndedWithGameWon:(self.numberOfHeartsLeft >= 0 && (self.numberOfHeartsLeft - [self numberOfObjectsLeftOfType:HUMAN]) >= 0)];
        } else {
            //  otherwise, we ask the delegate to remove those objs, and move all the objs down again
            [self.delegate objectsShouldDisappearAtTileCoords:removeSet ThenCallBlock:[self callbackBlockToMoveObjects]];
        }
    };
}

//  returns the callback block to move all moveable objects down the tiles until they reach the bottom
- (void (^)(void)) callbackBlockToMoveObjects
{
    return ^{
        NSMutableArray *fromCoords = [[NSMutableArray alloc] init];
        NSMutableArray *toCoords = [[NSMutableArray alloc] init];
        
        //  loop through all objs from the second last row, bottom row objs can't move
        for (int i = self.numberOfRows - 2; i >= 0 ; i--) {
            for (int j = self.numberOfColumns - 1; j >= 0 ; j--) {
                TileCoord *tc = [TileCoord coordWithRow:i AndColumn:j];
                ForegroundObject *obj = [self.foregroundObjects objectForKey:tc];
                
                //  if there is an obj and it is moveable, then try to move it down as far as possible
                if (obj && obj.moveable) {
                    int moveToRow = i;
                    
                    //  determine how many rows it can move
                    while (moveToRow++ != self.numberOfRows - 1) {
                        ForegroundObject *objBelow = [self.foregroundObjects objectForKey:[TileCoord coordWithRow:moveToRow AndColumn:j]];
                        if (objBelow)
                            break;
                    }
                    
                    //  this is the coord it moves to
                    TileCoord *moveTo = [TileCoord coordWithRow:moveToRow - 1 AndColumn:j];
                    
                    //  if the coords are different, then move obj
                    if (! [tc isEqual:moveTo]) {
                        [self.foregroundObjects removeObjectForKey:tc];
                        [self.foregroundObjects setObject:obj forKey:moveTo];
                        
                        [fromCoords addObject:tc];
                        [toCoords addObject:moveTo];
                    }
                }
            }
        }
        
            //  if there are objs to move, then ask delegate to move them and then execute the block to remove objects
        if ([fromCoords count] > 0) {
            [self.delegate moveObjectsAtTileCoord:fromCoords ToTileCoord:toCoords ThenCallBlock:[self callbackBlockToRemoveObjects]];
        } else {
            //  otherwise just execute block to remove objects
            [self callbackBlockToRemoveObjects]();
        }
    };
}

//  returns the NSSet of objects of the type in row, can return nil if there are no objs of the type in that row
- (NSSet *) setOfObjectsOfType: (foreground_object_t) type InRowNumber: (int) num 
{
    NSMutableSet *set = [[NSMutableSet alloc] init];
    for (int i = 0; i < self.numberOfColumns ; i++) {
        TileCoord *tc = [TileCoord coordWithRow:num AndColumn:i];
        ForegroundObject *obj = [self.foregroundObjects objectForKey:tc];
        if (obj && obj.type == type) {
            [set addObject:tc];
        }
    }
    return set;
}

//  returns the total number of TYPE objects left in the tile map
- (int) numberOfObjectsLeftOfType: (foreground_object_t) type
{
    int count = 0;
    for (int i = self.numberOfRows - 1; i >= 0 ; i--) {
        count += [[self setOfObjectsOfType:type InRowNumber:i] count];
    }
    return count;
} 

//  this method returns the objects matching matchObject and are in line at tile coord
//  it only checks the down and right directions, but if you run this check on every tile, then it can cover the entire tile map
//  this method returns all the gems that can in a continuous line, so even if there are more than GEM_LINE_QUANTITY objects connected, it'll return them all
- (NSSet *) setOfObjectsThatMatchObject: (ForegroundObject *) matchObject AndAreInLineAtTileCoord: (TileCoord *) coord
{
    //  gets set of objs that form line in down dir, and right dir
    NSSet *downSet = [self setOfObjectsThatMatchObject:matchObject AtTileCoord:coord WithRowOffset:1 AndColumnOffset:0];
    NSSet *rightSet = [self setOfObjectsThatMatchObject:matchObject AtTileCoord:coord WithRowOffset:0 AndColumnOffset:1];
    
    //  gets the count of each of these sets
    int downCount = [downSet count];
    int rightCount = [rightSet count];
    
    if (downCount >= GEM_LINE_QUANTITY && rightCount >= GEM_LINE_QUANTITY) {
        return [downSet setByAddingObjectsFromSet:rightSet];            //  if both lines have at least the quantity needed, merge sets and return that
    } else if (downCount >= GEM_LINE_QUANTITY) {
        return downSet;                                                 //  only down dir has line, return down set
    } else if (rightCount >= GEM_LINE_QUANTITY) {
        return rightSet;                                                //  only right dir has line, return right set
    }
    
    return nil;
}  

//  this method is used by the method above to loop and find the objects that match and add it to the set
//  it uses the offsets supplied to keep checking in that partiuclar direction until all objs matching in line are added to set
- (NSSet *) setOfObjectsThatMatchObject: (ForegroundObject *) matchObject AtTileCoord: (TileCoord *) coord WithRowOffset: (int) rowOffset AndColumnOffset: (int) colOffset
{
    NSMutableSet *set = [NSMutableSet setWithObject:coord];
    int depth = 1;
    TileCoord *checkCoord;
    
    while (YES) {
        //  update the check coord using the offsets, and get the obj at the check coords
        checkCoord = [TileCoord coordWithRow:coord.row + rowOffset * depth AndColumn:coord.column + colOffset * depth];
        id obj = [self.foregroundObjects objectForKey:checkCoord];
        
        if (obj == matchObject) {
            [set addObject:checkCoord];         //  if obj is a match, add it to set
        } else {
            break;                              //  if obj not match, break out of loop
        }
        depth++;
    }
    
    return set;
}



#pragma mark - getter/setters

//  just returning a constant as the number of rows used in app is always the same
- (int) numberOfRows
{
    return NUMBER_OF_ROWS;
}

//  just returning a constant as the number of columnss used in app is always the same
-(int) numberOfColumns
{
    return NUMBER_OF_COLUMNS;
}

//  sets the seconds left. if seconds left reaches 0, then calls endLevel
- (void) setSecondsLeft: (float) secondsLeft
{
    if (! self.finished) {
        if (secondsLeft <= 0) {
            [self endLevel];
        }
        _secondsLeft = secondsLeft;
    }
}

#pragma mark - NSCoding
//  NOTE: only variable state is stored. since the data is only used to restore previous games, the obj chances are not required.

//  see NSCoding
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInt:self.number forKey:LEVEL_NUMBER_ENCODER_KEY];
    [encoder encodeObject:self.foregroundObjects forKey:FOREGROUND_OBJECTS_ENCODER_KEY];
    [encoder encodeFloat:self.secondsLeft forKey:SECONDS_LEFT_ENCODER_KEY];
    [encoder encodeFloat:self.secondsAllowed forKey:SECONDS_ALLOWED_ENCODER_KEY];
    [encoder encodeInt:self.numberOfHeartsLeft forKey:NUM_HEARTS_LEFT_ENCODER_KEY];
    [encoder encodeBool:self.finished forKey:LEVEL_FINISHED_ENCODER_KEY];
    
}

//  see NSCoding
- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.number = [decoder decodeIntForKey:LEVEL_NUMBER_ENCODER_KEY];
        self.foregroundObjects = [decoder decodeObjectForKey:FOREGROUND_OBJECTS_ENCODER_KEY];
        self.secondsAllowed = [decoder decodeFloatForKey:SECONDS_ALLOWED_ENCODER_KEY];
        self.secondsLeft = [decoder decodeFloatForKey:SECONDS_LEFT_ENCODER_KEY];
        self.numberOfHeartsLeft = [decoder decodeIntForKey:NUM_HEARTS_LEFT_ENCODER_KEY];
        self.finished = [decoder decodeBoolForKey:LEVEL_FINISHED_ENCODER_KEY];
    }
    return self;
}

@end
