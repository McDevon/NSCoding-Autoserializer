//
//  TestSerializeObject.m
//  AutoSerializer
//
//  Created by Jussi Enroos on 6.9.2015.
//  Copyright (c) 2015 Jussi Enroos. All rights reserved.
//

#import "TestSerializeObject.h"

@implementation TestSerializeObject

- (NSString *)description
{
    NSMutableString *array = [NSMutableString string];
    for (NSObject *object in _arrayValue) {
        [array appendFormat:@"%@, ", object];
    }
    
    NSMutableString *dictionary = [NSMutableString string];
    NSArray *keys = [_dictionaryValue allKeys];
    for (NSObject *key in keys) {
        NSObject *value = [_dictionaryValue objectForKey:key];
        [dictionary appendFormat:@"%@: %@\n", key, value];
    }
    
    NSString * structObject = @"";
    
    return [NSString stringWithFormat:
            @"name: %@\n"
            @"int: %d\n"
            @"bool: %hhd\n"
            @"double: %f\n"
            @"float: %f\n"
            @"array: %@\n"
            @"dictionary: %@\n"
            @"owntype: %@\n"
            @"struct: %@\n",
            _name,
            _intValue,
            _booleanValue,
            _doubleValue,
            _floatValue,
            array,
            dictionary,
            _ownTypeValue,
            structObject];
}

@end
