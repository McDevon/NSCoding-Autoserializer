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

#define CALL_GETTER_FOR_TYPE(type) \
IMP imp = [self methodForSelector:selector]; \
type (*getter)(id, SEL) = (void *)imp; \
type value = getter(self, selector);

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
    
    // Iterate properties
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        NSString *nameString = [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding];
        
        const char *attributes = property_getAttributes(properties[i]);
        
        NSString *attributeData = [NSString  stringWithCString:attributes encoding:NSUTF8StringEncoding];
        
        // Check if this is a read-only property
        NSArray *attributeArray = [attributeData componentsSeparatedByString:@","];
        
        BOOL readOnly = NO;
        
        for (NSString *string in attributeArray) {
            if ([string isEqualToString:@"R"]) {
                // This is a read-only property, do not encode
                readOnly = YES;
                break;
            }
        }
        
        if (readOnly) {
            continue;
        }
        
        char type[2] = "\0\0";
        
        if ([attributeData length] > 1) {
            type[0] = attributes[1];
        }
        
        //ASLOG(@"Prop: %@: %@", nameString, attributeData);
        
        // Get the selector for this property
        SEL selector = NSSelectorFromString(nameString);
        
        // Sanity check
        if (!!! [self respondsToSelector:selector]) {
            continue;
        }
        
        // Get object type
        if (strncmp(type, "@", 2) == 0) {
            NSArray *separated = [attributeData componentsSeparatedByString:@"\""];
            
            // Only collect object types for properties, as they cannot be read from setter methods
            if (separated.count > 2) {
                NSString *typeInfo = [separated objectAtIndex:1];
                ASLOG(@"  Property: %@, type: %@", nameString, typeInfo);
                
                // Get possible class for the type
                Class class = NSClassFromString(typeInfo);
                
                if (class != nil && [class conformsToProtocol:@protocol(NSCoding)]) {
                    
                    CALL_GETTER_FOR_TYPE(id);
                    
                    [aCoder encodeObject:value forKey:nameString];
                    
                    ASLOG(@"Serializing %@ as object", nameString);
                }
            }
        }
        
        // Serialize non-object type properties
        else if (strncmp(type, @encode(int), 2) == 0) {
            
            CALL_GETTER_FOR_TYPE(int)
            [aCoder encodeInt:value forKey:nameString];
            
            ASLOG(@"Serializing %@ with value %d", nameString, value);
        }
        else if (strncmp(type, @encode(int32_t), 2) == 0) {
            
            CALL_GETTER_FOR_TYPE(int32_t)
            [aCoder encodeInt32:value forKey:nameString];
            
            ASLOG(@"Serializing %@ with value %d", nameString, value);
        }
        else if (strncmp(type, @encode(int64_t), 2) == 0) {
            
            CALL_GETTER_FOR_TYPE(int64_t)
            [aCoder encodeInt64:value forKey:nameString];
            
            ASLOG(@"Serializing %@ with value %lld", nameString, value);
        }
        else if (strncmp(type, @encode(float), 2) == 0) {
            
            CALL_GETTER_FOR_TYPE(float)
            [aCoder encodeFloat:value forKey:nameString];
            
            ASLOG(@"Serializing %@ with value %f", nameString, value);
        }
        else if (strncmp(type, @encode(double), 2) == 0) {
            
            CALL_GETTER_FOR_TYPE(double)
            [aCoder encodeDouble:value forKey:nameString];
            
            ASLOG(@"Serializing %@ with value %f", nameString, value);
        }
        else if (strncmp(type, @encode(BOOL), 2) == 0) {
            
            CALL_GETTER_FOR_TYPE(BOOL)
            [aCoder encodeBool:value forKey:nameString];
            
            ASLOG(@"Serializing %@ with value %hhd", nameString, value);
        }
        
        // TODO: Struct types
        
        // Serializing this property is not supported
        else {
            ASLOG(@"Serializing of type %s is not supported", type);
        }
        
    }
    free(properties);
    
    /*
     *  Create property rules for any found setters
     */
    
    /*Method* methods = class_copyMethodList([self class], &count);
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
    
    free(methods);*/
}

@end
