//
//  BHJSONValidator.h
//  BHJSONValidator
//
//  Created by Reynaldo on 3/13/14.
//  Copyright (c) 2014 Reynaldo. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BHJSONValidatorErrorDomain @"BHJSONValidatorErrorDomain"
#define BHJSONValidatorFailingKeys @"BHJSONValidatorFailingKeys"
#define BHJSONValidatorErrorBadRequirementsParameter 0
#define BHJSONValidatorErrorBadJSONParameter 1
#define BHJSONValidatorErrorInvalidJSON 2

@interface BHJSONValidator : NSObject

// Returns YES when json is "valid", i.e., all the requirements are met
+ (BOOL)validateValuesFrom:(id)json
          withRequirements:(NSDictionary *)requirements
                     error:(NSError **)error;

+ (NSString *)prettyStringGivenBHJSONValidatorError:(NSError *)error;

+ (void)setShouldSuppressLogging:(BOOL)shouldSuppressLogging;
@end
