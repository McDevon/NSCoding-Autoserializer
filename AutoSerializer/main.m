//
//  main.m
//  AutoSerializer
//
//  Created by Jussi Enroos on 6.9.2015.
//  Copyright (c) 2015 Jussi Enroos. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TestSerializeObject.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Running some tests");
        
        NSString *filePath = @"file.tst";
        BOOL save = NO;
        
        // Serialize
        if (save) {
            TestSerializeObject *object = [[TestSerializeObject alloc] init];
            
            // Some test values
            object.name = @"Moo";
            //object.anotherString = @"Another String";
            object.intValue = 10;
            //object.IntValue = 15;
            object.booleanValue = YES;
            object.doubleValue = 423.5433;
            object.arrayValue = @[@"One", @"Two", @"Three"];
            object.dictionaryValue = @{@"Key": @"Value"};
            object.ownTypeValue = [[TestSerializeObject alloc] init];
            object.structValue = CGSizeMake(100.f, 50.f);
            
            [NSKeyedArchiver archiveRootObject:object toFile:filePath];
        }
        
        
        // Deserialize
        else {
            TestSerializeObject *object = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
            
            NSLog(@"Loaded object:\n%@", object);
        }
        
        
        
        
    }
    return 0;
}
