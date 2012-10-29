//
//  ForegroundObject.m
//  GemEscape
//
//  Implements ForegroundObject.h
//
//  Created by Peter Lin on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ForegroundObject.h"

//  various keys used in encoding and decoding this object
#define TYPE_ENCODER_KEY @"TYPE_ENCODER_KEY"
#define MOVEABLE_ENCODER_KEY @"MOVEABLE_ENCODER_KEY"
#define SWAPPABLE_ENCODER_KEY @"SWAPPABLE_ENCODER_KEY"
#define IMAGE_FILE_ENCODER_KEY @"IMAGE_FILE_ENCODER_KEY"

@implementation ForegroundObject
@synthesize imageFilename = _imageFilename;
@synthesize swappable = _swappable;
@synthesize type = _type;
@synthesize moveable = _moveable;

#pragma mark - NSCoding

//  encodes this object for archieving
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeBool:self.moveable forKey:MOVEABLE_ENCODER_KEY];
    [encoder encodeObject:self.imageFilename forKey:IMAGE_FILE_ENCODER_KEY];
    [encoder encodeBool:self.swappable forKey:SWAPPABLE_ENCODER_KEY];
    [encoder encodeInt:self.type forKey:TYPE_ENCODER_KEY];
}

//  decodes an archieved object of this type
- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.moveable = [decoder decodeBoolForKey:MOVEABLE_ENCODER_KEY];
        self.swappable = [decoder decodeBoolForKey:SWAPPABLE_ENCODER_KEY];
        self.imageFilename = [decoder decodeObjectForKey:IMAGE_FILE_ENCODER_KEY];
        self.type = [decoder decodeIntForKey:TYPE_ENCODER_KEY];
    }
    return self;
}

@end
