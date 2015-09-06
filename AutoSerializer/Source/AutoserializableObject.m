//
//  AutoserializableObject.m
//  AutoSerializer
//
//  Created by Jussi Enroos on 6.9.2015.
//  Copyright (c) 2015 Jussi Enroos. All rights reserved.
//

#import "AutoserializableObject.h"

#import <objc/runtime.h>

#define MAX_STRUCT_NAME_LENGTH 128

#ifdef DEBUG

#define __AUTOSERIALIZERLOG(s, ...) \
NSLog(@"#Autoserializer: %@",[NSString stringWithFormat:(s), ##__VA_ARGS__])

// Debug logging for serializer
#define ENABLE_ASLOG
//#undef ENABLE_ASLOG

#endif

// If disabled, ASLOG should be nop or nothing
#ifdef ENABLE_ASLOG
#   define ASLOG(...) __AUTOSERIALIZERLOG(__VA_ARGS__)
#else
#   define ASLOG(...) do {} while (0)
#endif

@implementation AutoserializableObject 

- (NSArray *)autoSerializerBlacklist
{
    return nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    // Go through all the properties this object has
    
    /*
     *  Get property types
     */
    
    uint count;
    
    objc_property_t* properties = class_copyPropertyList([self class], &count);
    NSMutableDictionary* propertyDictionary = [NSMutableDictionary dictionary];
    
    // Iterate properties
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        NSString *nameString = [NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding];
        
        const char *attributes = property_getAttributes(properties[i]);
        
        NSString *attributeData = [NSString  stringWithCString:attributes encoding:NSUTF8StringEncoding];
        ASLOG(@"Prop: %@: %@", nameString, attributeData);
        NSArray *separated = [attributeData componentsSeparatedByString:@"\""];
        
        // Only collect object types for properties, as they cannot be read from setter methods
        if (separated.count > 2) {
            NSString *typeInfo = [separated objectAtIndex:1];
            ASLOG(@"  Property: %@, type: %@", nameString, typeInfo);
            
            // Add object property type to dictionary for possible further use
            [propertyDictionary setObject:typeInfo forKey:[nameString lowercaseString]];
        }
        
    }
    free(properties);
    
    /*
     *  Create property rules for any found setters
     */
    
    Method* methods = class_copyMethodList([self class], &count);
    for (int i = 0; i < count ; i++)
    {
        SEL selector = method_getName(methods[i]);
        const char* methodName = sel_getName(selector);
        NSString *nameString = [NSString  stringWithCString:methodName encoding:NSUTF8StringEncoding];
        
        ASLOG(@"  Method: %@", nameString);
        
        // Check if the method is a setter
        if (nameString.length <= 3 || !!! [nameString hasPrefix:@"set"] || methodName[3] < 'A' || methodName[3] > 'Z') {
            // Not a setter
            continue;
        }
        
        int argCount = method_getNumberOfArguments(methods[i]);
        
        // Check argument count, should be 3 for regular setter
        if (argCount != 3) {
            // Not a setter
            continue;
        }
        
        ASLOG(@"    is a setter");
        
        // Get the name of property to set
        NSString *propertyName = [[[nameString substringFromIndex:3] lowercaseString] stringByReplacingOccurrencesOfString:@":" withString:@""];
        ASLOG(@"    of property: %@", propertyName);
        
        // Get property type
        char at[MAX_STRUCT_NAME_LENGTH] = {0,};
        method_getArgumentType(methods[i], 2, at, MAX_STRUCT_NAME_LENGTH);
        ASLOG(@"    3rd arg type: %s", at);
    }
    
    free(methods);
}

@end
