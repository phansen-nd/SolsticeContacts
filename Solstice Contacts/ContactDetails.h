//
//  ContactDetails.h
//  Solstice Contacts
//
//  Created by Patrick on 7/24/15.
//  Copyright (c) 2015 Patrick Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ContactBasic;

@interface ContactDetails : NSManagedObject

@property (nonatomic, retain) NSNumber * favorite;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * website;
@property (nonatomic, retain) NSNumber * employeeId;
@property (nonatomic, retain) NSString * largeImageURL;
@property (nonatomic, retain) NSDictionary * address;
@property (nonatomic, retain) NSData * largeImageData;
@property (nonatomic, retain) ContactBasic *basic;

@end
