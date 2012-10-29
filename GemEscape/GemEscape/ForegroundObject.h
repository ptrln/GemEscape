//
//  ForegroundObject.h
//  GemEscape
//
//  This is the objects that are displayed in the foreground in tiles.
//  Implements NSCoding for storage in NSUserDefaults
//
//  Created by Peter Lin on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

//  this defines the enum of the various types of foreground objects
//  this type is useful because sometimes we are only interested in a object of a certain type
typedef enum {
    HUMAN,
    GEM,
    BLOCK,
    ENEMY, 
    HEART,
    STAR
} foreground_object_t;

@interface ForegroundObject : NSObject <NSCoding>
@property (nonatomic, assign) foreground_object_t type;     //  the type of the object
@property (nonatomic, strong) NSString *imageFilename;      //  the image file of the object
@property (nonatomic, assign) BOOL swappable;               //  the object is swappable
@property (nonatomic, assign) BOOL moveable;                //  the object is moveable
@end
