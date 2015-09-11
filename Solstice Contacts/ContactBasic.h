//
//  ContactBasic.h
//  Solstice Contacts
//
//  Created by Patrick on 7/24/15.
//  Copyright (c) 2015 Patrick Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ContactDetails;

@interface ContactBasic : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * company;
@property (nonatomic, retain) NSNumber * employeeId;
@property (nonatomic, retain) NSDictionary * phone;
@property (nonatomic, retain) NSString * smallImageURL;
@property (nonatomic, retain) NSString * birthdate;
@property (nonatomic, retain) NSString * detailsURL;
@property (nonatomic, retain) NSData * smallImageData;
@property (nonatomic, retain) ContactDetails *details;

@end
