//
//  AutoserializableObject.h
//  AutoSerializer
//
//  Created by Jussi Enroos on 6.9.2015.
//  Copyright (c) 2015 Jussi Enroos. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 *  All subclasses of this object can be serialized automatically.
 *
 *  The serializing and deserializing methods will serialize and
 *  deserialize all properties, which have both setters and getters.
 */

@interface AutoserializableObject : NSObject <NSCoding>

// Override this method to list all properties, which should not be automatically serialized
+ (NSArray*) autoSerializerBlacklist;

@end
