//
//  BHJSONValidator.m
//  BHJSONValidator
//
//  Created by Reynaldo on 3/13/14.
//  Copyright (c) 2014 Reynaldo. All rights reserved.
//

#import "BHJSONValidator.h"
#import "BHValidatorPredicate.h"

static BOOL BHJSONValidatorShouldSuppressWarnings;

@interface BHValidatorPredicate(Protected)
- (void)validateValue:(id)value withKey:(NSString *)key;
- (NSMutableArray *)failedRequirementDescriptions;
@end

@implementation BHJSONValidator

+ (BOOL)validateValuesFrom:(id)json
          withRequirements:(NSDictionary *)requirements
                     error:(NSError **)error {
    // The json parameter must be an NSArray or NSDictionary with
    // NSString keys and NSString/NSNumber/NSNull/NSDictionary/NSArray values
    //
    // The requirements parameter must be an NSDictionary with these specifications:
    // * Keys: NSString/NSNumber
    // * Values: BHValidatorPredicate/NSDictionary
    //
    // The error parameter may be nil. Otherwise, it must be an NSError class
    
    if(!json) {
        [BHJSONValidator log:@"BHJSONValidator Error: json parameter is nil -- there is nothing to validate. Returning NO"];
        if(error) {
            *error = [NSError errorWithDomain:BHJSONValidatorErrorDomain
                                         code:BHJSONValidatorErrorBadJSONParameter
                                     userInfo:@{
                                                NSLocalizedDescriptionKey : @"Nothing to validate",
                                                NSLocalizedFailureReasonErrorKey : @"json parameter is nil",
                                                NSLocalizedRecoverySuggestionErrorKey : @"pass in valid json"
                                                }];
        }
        
        return NO;
    }
    
    if(![json isKindOfClass:[NSDictionary class]] && ![json isKindOfClass:[NSArray class]]) {
        [BHJSONValidator log:@"BHJSONValidator Error: json parameter is not valid JSON (it is not an NSArray or NSDictionary). Returning NO"];
        if(error) {
            *error = [NSError errorWithDomain:BHJSONValidatorErrorDomain
                                         code:BHJSONValidatorErrorBadJSONParameter
                                     userInfo:@{
                                                NSLocalizedDescriptionKey : @"Nothing to validate",
                                                NSLocalizedFailureReasonErrorKey : @"json parameter is not an NSArray or NSDictionary",
                                                NSLocalizedRecoverySuggestionErrorKey : @"pass in valid json"
                                                }];
        }
        return NO;
    }
    
    if(!requirements) {
        [BHJSONValidator log:@"BHJSONValidator Error: requirements parameter is nil -- there are no requirements. Returning NO"];
        if(error) {
            *error = [NSError errorWithDomain:BHJSONValidatorErrorDomain
                                         code:BHJSONValidatorErrorBadRequirementsParameter
                                     userInfo:@{
                                                NSLocalizedDescriptionKey : @"Nothing to validate",
                                                NSLocalizedFailureReasonErrorKey : @"requirements parameter is nil",
                                                NSLocalizedRecoverySuggestionErrorKey : @"pass in valid requirements"
                                                }];
        }
        return NO;
    }
    
    if(![requirements isKindOfClass:[NSDictionary class]]) {
        [BHJSONValidator log:@"BHJSONValidator Error: requirements parameter is not an NSDictionary. Returning NO"];
        if(error) {
            *error = [NSError errorWithDomain:BHJSONValidatorErrorDomain
                                         code:BHJSONValidatorErrorBadRequirementsParameter
                                     userInfo:@{
                                                NSLocalizedDescriptionKey : @"Nothing to validate",
                                                NSLocalizedFailureReasonErrorKey : @"requirements parameter is not an NSDictionary",
                                                NSLocalizedRecoverySuggestionErrorKey : @"pass in valid requirements"
                                                }];
        }
        return NO;
    }
    
    return [BHJSONValidator validateValuesFrom:json
                              withRequirements:requirements
                                         error:error
                                      userInfo:[@{} mutableCopy]];
}

+ (BOOL)validateValuesFrom:(id)json
          withRequirements:(NSDictionary *)requirements
                     error:(NSError **)error
                  userInfo:(NSMutableDictionary *)userInfo {
    // The json parameter must be an NSArray or NSDictionary with
    // NSString keys and NSString/NSNumber/NSNull/NSDictionary/NSArray values
    //
    // The requirements parameter must be an NSDictionary with these specifications:
    // * Keys: NSString/NSNumber
    //      * Keys correspond to JSON keys or indices of arrays
    // * Values: BHValidatorPredicate/NSDictionary
    
    __block BOOL encounteredError = NO;
    [requirements enumerateKeysAndObjectsUsingBlock:^(id requirementsKey, id requirementsValue, BOOL *stop) {
        
        id jsonValue;
        
        if([json isKindOfClass:[NSArray class]] && [requirementsKey isKindOfClass:[NSNumber class]] && [json count] > [requirementsKey unsignedIntegerValue]) {
            jsonValue = [json objectAtIndex:[requirementsKey unsignedIntegerValue]];
        } else if([json isKindOfClass:[NSDictionary class]]) {
            jsonValue = [json objectForKey:requirementsKey];
        } else {
            jsonValue = nil;
        }
        
        if([requirementsValue isKindOfClass:[BHValidatorPredicate class]] && [requirementsKey isKindOfClass:[NSString class]]) {
            [(BHValidatorPredicate *)requirementsValue validateValue:jsonValue withKey:requirementsKey];
            
            if([[(BHValidatorPredicate *)requirementsValue failedRequirementDescriptions] count]) {
                NSMutableDictionary *failingKeys = [userInfo objectForKey:BHJSONValidatorFailingKeys];
                
                if(failingKeys) failingKeys = [failingKeys mutableCopy];
                else failingKeys = [NSMutableDictionary dictionary];
                
                [failingKeys setObject:[(BHValidatorPredicate *)requirementsValue failedRequirementDescriptions] forKey:requirementsKey];
                [userInfo setObject:failingKeys forKey:BHJSONValidatorFailingKeys];
            }
        } else if([requirementsValue isKindOfClass:[NSDictionary class]]) {
            [BHJSONValidator validateValuesFrom:jsonValue
                               withRequirements:requirementsValue
                                          error:error
                                       userInfo:userInfo];
        } else {
            [BHJSONValidator log:[NSString stringWithFormat:@"BHJSONValidator Error: requirements parameter isn't valid. Value (%@) isn't an BHValidatorPredicate or NSDictionary or NSNumber. Returning NO", requirementsValue]];
            
            encounteredError = YES;
            if (error) {
                *error = [NSError errorWithDomain:BHJSONValidatorErrorDomain
                                             code:BHJSONValidatorErrorBadRequirementsParameter
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey : @"Requirements not setup correctly",
                                                    NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"Requirements key (%@) with value (%@) is not an BHValidatorPredicate or NSDictionary", requirementsKey, requirementsValue],
                                                    NSLocalizedRecoverySuggestionErrorKey : @"Review requirements syntax"
                                                    }];
            }
            
            *stop = YES;
        }
        
    }];
    
    if (encounteredError) {
        return NO;
    }
    
    if([[userInfo allKeys] count]) {
        if (error) {
            [userInfo setObject:@"JSON did not validate" forKey:NSLocalizedDescriptionKey];
            [userInfo setObject:@"At least one requirement wasn't met" forKey:NSLocalizedFailureReasonErrorKey];
            [userInfo setObject:@"Perhaps use backup JSON" forKey:NSLocalizedRecoverySuggestionErrorKey];

            *error = [NSError errorWithDomain:BHJSONValidatorErrorDomain code:BHJSONValidatorErrorInvalidJSON userInfo:userInfo];
        }
        return NO;
    }
    return YES;
}

+ (NSString *)prettyStringGivenBHJSONValidatorError:(NSError *)error {
    __block NSString *prettyString = @"";
    
    NSDictionary *failingKeys = [[error userInfo] objectForKey:BHJSONValidatorFailingKeys];
    
    [failingKeys enumerateKeysAndObjectsUsingBlock:^(NSString *badKey, NSArray *requirements, BOOL *stop) {
        prettyString = [prettyString stringByAppendingFormat:@"* %@\n", badKey];
        
        for (NSString *requirement in requirements) {
            prettyString = [prettyString stringByAppendingFormat:@"     * %@\n", requirement];
        }
    }];
    
    return prettyString;
}

+ (void)setShouldSuppressLogging:(BOOL)shouldSuppressLogging {
    BHJSONValidatorShouldSuppressWarnings = shouldSuppressLogging;
}

+ (void)log:(NSString *)warning {
    if(!BHJSONValidatorShouldSuppressWarnings)
        NSLog(@"%@", warning);
}

@end
