//
//  ContactDetailViewController.h
//  Solstice Contacts
//
//  Created by Patrick on 7/23/15.
//  Copyright (c) 2015 Patrick Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactDetails.h"

@interface ContactDetailViewController : UIViewController <UIActionSheetDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *headshotImageView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *companyLabel;
@property (nonatomic, weak) IBOutlet UILabel *homePhoneLabel;
@property (nonatomic, weak) IBOutlet UILabel *workPhoneLabel;
@property (nonatomic, weak) IBOutlet UILabel *mobilePhoneLabel;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UILabel *emailLabel;
@property (nonatomic, weak) IBOutlet UILabel *birthdateLabel;
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *favoriteButton;
@property (nonatomic, weak) IBOutlet UIButton *editContactButton;
@property (nonatomic, weak) IBOutlet UIButton *websiteButton;
@property (nonatomic, weak) IBOutlet UIButton *callLaunchButton;
@property (nonatomic, weak) IBOutlet UIButton *mapsLaunchButton;
@property (nonatomic, weak) IBOutlet UIButton *emailLaunchButton;

@property (nonatomic, strong) ContactDetails *contactDetails;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

-(IBAction)launchPhone:(id)sender;
-(IBAction)launchMaps:(id)sender;
-(IBAction)launchEmail:(id)sender;
-(IBAction)toggleFavorite:(id)sender;
-(IBAction)launchWebsite:(id)sender;

@end
