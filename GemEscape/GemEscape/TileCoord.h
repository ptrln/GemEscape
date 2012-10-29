//
//  TileCoord.h
//  GemEscape
//
//  This is the object representing the coords of the object in terms of the tile map.
//  This obj can be archieve and can be safely used in OBJ-C containers as keys
//
//  Created by Peter Lin on 22/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TileCoord : NSObject <NSCopying, NSCoding>

//  row and column coords
@property (nonatomic, assign) int row;
@property (nonatomic, assign) int column;

//  creation method to create a tile coord with row and column
+ (TileCoord *) coordWithRow: (int) row AndColumn: (int) col;

@end
