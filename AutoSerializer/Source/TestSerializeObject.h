//
//  TestSerializeObject.h
//  AutoSerializer
//
//  Created by Jussi Enroos on 6.9.2015.
//  Copyright (c) 2015 Jussi Enroos. All rights reserved.
//

#import "AutoserializableObject.h"

@interface TestSerializeObject : AutoserializableObject

@property (copy) NSString *name;
@property int intValue;
//@property int IntValue;
@property (readonly) int anotherIntValue;
@property (readonly, strong) NSString *anotherString;
@property BOOL booleanValue;
@property double doubleValue;
@property float floatValue;

@property NSArray *arrayValue;
@property NSDictionary *dictionaryValue;

@property (strong) TestSerializeObject *ownTypeValue;
@property CGSize structValue;

@end
