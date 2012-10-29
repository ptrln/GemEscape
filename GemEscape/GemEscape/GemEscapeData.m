//
//  GemEscapeData.m
//  GemEscape
//
//  This implements the GemEscapeData.h
//
//  Created by Peter Lin on 28/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GemEscapeData.h"

#define LEVELS_PLIST @"GemEscapeLevels"                 //  name of plist for levels dats
#define OBJECTS_PLIST @"GemEscapeObjects"               //  name of plist for objects
#define DEFAULT_LEVEL_REACHED 1                         //  this is the default level number if nothing is stored
#define SAVED_PROGRESS_KEY @"GemEscape.SavedGameProgress"           //  this is the key for saved progress
#define LEVEL_REACHED_KEY @"GemEscape.HighestLevelReached"          //  this is the key for highest level reached

@implementation GemEscapeData

//  this is the levels data cache which just caches the data since it'll never change at run time
static NSDictionary *levelsDataCache = nil;

//  this caches the foreground objects as they will never change at run time
static NSDictionary *gemEscapeObjects = nil;

//  see GemEscapeData.h
+ (NSDictionary *) levelsData 
{
    //  if the cache is nil, load the levels data from the property list
    if (! levelsDataCache) {
        NSString *path=[[NSBundle mainBundle] pathForResource:LEVELS_PLIST ofType:@"plist"];
        levelsDataCache = [NSDictionary dictionaryWithContentsOfFile:path];
    }
    return levelsDataCache;
}

//  see GemEscapeData.h
+ (int) highestLevelNumberReached
{
    //  try to load the level reached. if no record, then just return the default level reached
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger level = [defaults integerForKey:LEVEL_REACHED_KEY];
    
    if (level)
        return level;
    else
        return DEFAULT_LEVEL_REACHED;
}

//  see GemEscapeData.h
+ (void) setHighestLevelNumberReachedTo: (int) levelNumber
{
    //  save the level reached to NSUserDefaults. 
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:levelNumber] forKey:LEVEL_REACHED_KEY];
    [defaults synchronize];
}

//  see GemEscapeData.h
+ (GemEscapeLevel *) savedLevelProgress;
{
    //  load the saved progress from NSUserDefaults 
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:SAVED_PROGRESS_KEY];
    
    //  if nil, then return nil, otherwise return the saved level
    if (data)
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    else
        return nil;
}

//  see GemEscapeData.h
+ (void) setSavedLevelProgress: (GemEscapeLevel *) level
{
    //  save the level to NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //  if the level passed in not nil, then save it, otherwise remove any existing progress
    if (level)
        [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:level] forKey:SAVED_PROGRESS_KEY];
    else
        [defaults removeObjectForKey:SAVED_PROGRESS_KEY];
    [defaults synchronize];
}

//  helper function to create all of the objects specified in the property list into real objects and cache them
+ (void) loadGemEscapeObjects
{
    //  in this implementation, all of the objects are created using the data stored in a object property list
    //  this allows easy specification of objects, easy to add or remove objects as required
    
    //  this is temp dict to hold the objects created
    NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] init];
    
    //  load the object property list
    NSString *path=[[NSBundle mainBundle] pathForResource:OBJECTS_PLIST ofType:@"plist"];
    NSDictionary *objsDefinition = [NSDictionary dictionaryWithContentsOfFile:path];

    for (NSString *type in [objsDefinition allKeys]) {
        //  for each type of object in property list, store them in an array
        NSMutableArray *tmpArr = [[NSMutableArray alloc] init];
        foreground_object_t objType = [[self class] getTypeFromNSString:type];
        
        //  for each obj defined, add to dictionary
        for (NSDictionary *objDef in [objsDefinition objectForKey:type]) {
            ForegroundObject *obj = [[ForegroundObject alloc] init];
            obj.swappable = [[objDef objectForKey:@"swappable"] boolValue];
            obj.moveable = [[objDef objectForKey:@"moveable"] boolValue];
            obj.type = objType;
            obj.imageFilename = [objDef objectForKey:@"imageFilename"];
            [tmpArr addObject:obj];
        }
        
        //  add object to cache
        [tmpDict setObject: tmpArr forKey:[NSNumber numberWithInt:objType]];
    }
    
    gemEscapeObjects = tmpDict;
}

//  gets the foreground_object_t enum from the string name. doing this reduces later string comparisons significantly
+ (foreground_object_t) getTypeFromNSString: (NSString *) typeString
{
    if ([[typeString uppercaseString] isEqualToString:@"GEM"]) {
        return GEM;
    }
    if ([[typeString uppercaseString] isEqualToString:@"ENEMY"]) {
        return ENEMY;
    }
    if ([[typeString uppercaseString] isEqualToString:@"BLOCK"]) {
        return BLOCK;
    }
    if ([[typeString uppercaseString] isEqualToString:@"HUMAN"]) {
        return HUMAN;
    }
    if ([[typeString uppercaseString] isEqualToString:@"STAR"]) {
        return STAR;
    }
    return HEART;
}

//  see GemEscapeData.h
+ (ForegroundObject *) getRandomForegroundObjectOfType: (foreground_object_t) type 
{
    //  if not loaded objects, then load them
    if (! gemEscapeObjects)
        [[self class] loadGemEscapeObjects];

    //  get the array of objs of type, and return a random one
    NSArray *objs = [gemEscapeObjects objectForKey:[NSNumber numberWithInt:type]];
    if ([objs count]) {
        return [objs objectAtIndex:arc4random() % [objs count]];
    } else {
        return nil;
    }
}

//  see GemEscapeData.h
+ (ForegroundObject *) getRandomForegroundGemObjectWithPoolSizeOf: (int) size
{
    //  if not loaded objects, then load them
    if (! gemEscapeObjects)
        [[self class] loadGemEscapeObjects];
    
    //  get the array of objs of GEM type, and return a random one, only using the indexes 
    //  as specified by pool size
    NSArray *objs = [gemEscapeObjects objectForKey:[NSNumber numberWithInt:GEM]];
    if ([objs count]) {
        return [objs objectAtIndex:arc4random() % size];
    } else {
        return nil;
    }
}
@end
