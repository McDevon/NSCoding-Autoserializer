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

// Getter and setter calling as macros to avoid typos
#define CALL_GETTER_FOR_TYPE(type) \
IMP imp = [self methodForSelector:selector]; \
type (*getter)(id, SEL) = (void *)imp; \
type value = getter(self, selector);

#define CALL_SETTER_FOR_TYPE(type) \
IMP imp = [self methodForSelector:selector]; \
void (*setter)(id, SEL, type) = (void *)imp; \
setter(self, selector, value); \

#ifdef DEBUG

#define __AUTOSERIALIZERLOG(s, ...) \
NSLog(@"#Autoserializer: %@",[NSString stringWithFormat:(s), ##__VA_ARGS__])

// Debug logging for serializer
#define ENABLE_ASLOG
#undef ENABLE_ASLOG

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
        
        // Go through all the properties this object has
        
        // TODO: Also go through properties for parent class?
        
        uint count;
        
        objc_property_t* properties = class_copyPropertyList([self class], &count);
        
        NSArray *blackList = [self autoSerializerBlacklist];
        
        // Iterate properties
        for (int i = 0; i < count ; i++)
        {
            const char* propertyName = property_getName(properties[i]);
            NSString *nameString = [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding];
            
            // Do not serialize blacklisted properties
            if (blackList != nil && [blackList containsObject:nameString]) {
                continue;
            }
            
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
            
            // Get the setter selector for this property
            NSString *setterName = [NSString stringWithFormat:@"set%@%@:",
                                    [[nameString substringToIndex:1] uppercaseString],
                                    [nameString substringFromIndex:1]];
            
            ASLOG(@"Setter name: %@", setterName);
            
            SEL selector = NSSelectorFromString(setterName);
            
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
                        
                        id value = [aDecoder decodeObjectForKey:nameString];

                        CALL_SETTER_FOR_TYPE(id);
                        
                        ASLOG(@"Deserializing %@ as object", nameString);
                    }
                }
            }
            
            // Serialize non-object type properties
            else if (strncmp(type, @encode(int), 2) == 0) {
                
                int value = [aDecoder decodeIntForKey:nameString];
                CALL_SETTER_FOR_TYPE(int)
                
                ASLOG(@"Deserializing %@ with value %d", nameString, value);
            }
            else if (strncmp(type, @encode(int32_t), 2) == 0) {
                
                int32_t value = [aDecoder decodeInt32ForKey:nameString];
                CALL_SETTER_FOR_TYPE(int32_t)
                
                ASLOG(@"Deserializing %@ with value %d", nameString, value);
            }
            else if (strncmp(type, @encode(int64_t), 2) == 0) {
                
                int64_t value = [aDecoder decodeInt64ForKey:nameString];
                CALL_SETTER_FOR_TYPE(int64_t)
                
                ASLOG(@"Deserializing %@ with value %lld", nameString, value);
            }
            else if (strncmp(type, @encode(float), 2) == 0) {
                
                float value = [aDecoder decodeFloatForKey:nameString];
                CALL_SETTER_FOR_TYPE(float)
                
                ASLOG(@"Deserializing %@ with value %f", nameString, value);
            }
            else if (strncmp(type, @encode(double), 2) == 0) {
                
                double value = [aDecoder decodeDoubleForKey:nameString];
                CALL_SETTER_FOR_TYPE(double)
                
                ASLOG(@"Deserializing %@ with value %f", nameString, value);
            }
            else if (strncmp(type, @encode(BOOL), 2) == 0) {
                
                BOOL value = [aDecoder decodeBoolForKey:nameString];
                CALL_SETTER_FOR_TYPE(BOOL)
                
                ASLOG(@"Deserializing %@ with value %hhd", nameString, value);
            }
            
            // TODO: Struct types
            
            // Deserializing this property is not supported
            else {
                ASLOG(@"Deserializing of type %s is not supported", type);
            }
            
        }
        free(properties);
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    // Go through all the properties this object has
    
    uint count;
    
    objc_property_t* properties = class_copyPropertyList([self class], &count);
    
    NSArray *blackList = [self autoSerializerBlacklist];
    
    // Iterate properties
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        NSString *nameString = [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding];
        
        // Do not serialize blacklisted properties
        if (blackList != nil && [blackList containsObject:nameString]) {
            continue;
        }
        
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
                    
                    if (value != nil) {
                        [aCoder encodeObject:value forKey:nameString];
                    
                        ASLOG(@"Serializing %@ as object", nameString);
                    }
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
}

@end
