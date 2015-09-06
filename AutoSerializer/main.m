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
        
        TestSerializeObject *object = [[TestSerializeObject alloc] init];
        
        NSString *filePath = @"file.tst";
        
        [NSKeyedArchiver archiveRootObject:object toFile:filePath];
        
    }
    return 0;
}
