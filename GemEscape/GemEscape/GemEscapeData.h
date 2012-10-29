//
//  GemEscapeData.h
//  GemEscape
//
//  This class provides various class methods for easier access to the data used in GemEscape. This provides
//  the interface for data used, and the implementation can be implemented in the .m as required
//
//  Created by Peter Lin on 28/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GemEscapeLevel.h"
#import "ForegroundObject.h"

@interface GemEscapeData : NSObject
//  this method returns the NSDictionary of the levels data, the index of the dictionary is the level's number as NSNumber
+ (NSDictionary *) levelsData;

//  this method returns the highest level number reached by the user
+ (int) highestLevelNumberReached;

//  this method sets the highest level number reached. this method does not check that the levelNumber passed is higher
//  than the existing record
+ (void) setHighestLevelNumberReachedTo: (int) levelNumber;

//  this method returns the saved level progress, can be nil is no progress is saved
+ (GemEscapeLevel *) savedLevelProgress;

//  this method sets the saved level progress to the level passed in. if nil is passed in, the progress is cleared
+ (void) setSavedLevelProgress: (GemEscapeLevel *) level;

//  this method returns a random foreground object of a certain foreground object type
+ (ForegroundObject *) getRandomForegroundObjectOfType: (foreground_object_t) type;

//  this method returns a random gem from a gem variation pool size supplied
+ (ForegroundObject *) getRandomForegroundGemObjectWithPoolSizeOf: (int) size;
@end
