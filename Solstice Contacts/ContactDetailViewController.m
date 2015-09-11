//
//  ContactDetailViewController.m
//  Solstice Contacts
//
//  Created by Patrick on 7/23/15.
//  Copyright (c) 2015 Patrick Hansen. All rights reserved.
//

#import "ContactDetailViewController.h"
#import "ContactBasic.h"
#import <MapKit/MapKit.h>
#import "AppDelegate.h"
#import "EditContactViewController.h"

@interface ContactDetailViewController ()

@end

@implementation ContactDetailViewController

@synthesize headshotImageView;
@synthesize nameLabel;
@synthesize companyLabel;
@synthesize homePhoneLabel;
@synthesize workPhoneLabel;
@synthesize mobilePhoneLabel;
@synthesize addressLabel;
@synthesize emailLabel;
@synthesize birthdateLabel;
@synthesize contentView;
@synthesize favoriteButton;
@synthesize websiteButton;
@synthesize editContactButton;
@synthesize callLaunchButton;
@synthesize mapsLaunchButton;
@synthesize emailLaunchButton;

@synthesize contactDetails;
@synthesize managedObjectContext;

- (void)viewDidLoad {
    [super viewDidLoad];

    // Start scrollView after the nav bar, but scroll behind it! Nice setting
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // Get managed object context
    managedObjectContext = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    // Set up name, company and image
    NSString* formattedName = [contactDetails.basic.name stringByReplacingOccurrencesOfString:@" " withString:@"\n"];
    nameLabel.text = formattedName;
    companyLabel.adjustsFontSizeToFitWidth = YES;
    companyLabel.text = contactDetails.basic.company;
    headshotImageView.image = [UIImage imageWithData:contactDetails.largeImageData];
    headshotImageView.layer.cornerRadius = 8.0f;
    headshotImageView.clipsToBounds = YES;
    
    // Set up phone numbers
    homePhoneLabel.text = [contactDetails.basic.phone objectForKey:@"home"];
    workPhoneLabel.text = [contactDetails.basic.phone objectForKey:@"work"];
    mobilePhoneLabel.text = [contactDetails.basic.phone objectForKey:@"mobile"];
    
    // Set up address
    NSString *street = [contactDetails.address objectForKey:@"street"];
    NSString *city = [contactDetails.address objectForKey:@"city"];
    NSString *state = [contactDetails.address objectForKey:@"state"];
    NSString *zip = [contactDetails.address objectForKey:@"zip"];
    NSMutableString *rowAddress = [NSMutableString stringWithFormat:@"%@\n%@, %@ %@", street, city, state, zip];
    addressLabel.text = rowAddress;
    
    // Set up email
    emailLabel.text = contactDetails.email;
    
    // Set up birthdate
    if (contactDetails.basic.birthdate != nil && ![contactDetails.basic.birthdate isEqualToString:@"0"]) {
        int birthdateInt = [contactDetails.basic.birthdate intValue];
        NSDate *birthdate = [NSDate dateWithTimeIntervalSince1970:birthdateInt];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMMM d"];
        NSString *formattedDate = [dateFormatter stringFromDate:birthdate];
        // Age stuff
        /*NSDate *present = [NSDate date];
        NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:birthdate toDate:present options:0];
        NSInteger age = [dateComponents year];
        NSString *firstName = [self getFirstName:contactDetails.basic.name];
        NSString *ageString = (age > 18) ? [NSString stringWithFormat:@"(%@ is %ld)", firstName, (long)age] : @"";
        NSString *fullBirthdayString = [NSString stringWithFormat:@"%@ %@", formattedDate, ageString];*/
        birthdateLabel.text = formattedDate;
    } else {
        birthdateLabel.text = @"";
    }
        
    // Set favorite button to correct status
    if ([contactDetails.favorite boolValue] == YES) {
        favoriteButton.image = [UIImage imageNamed:@"favorite.png"];
    } else {
        favoriteButton.image = [UIImage imageNamed:@"not-favorite.png"];        
    }
    
    // Set up website
    [websiteButton setTitle:contactDetails.website forState:UIControlStateNormal];
}

#pragma mark - Button actions

// Create an action sheet based on the available phone numbers (action sheet delegate methods below)
-(IBAction)launchPhone:(id)sender {
    
    UIActionSheet *numberActionSheet = [[UIActionSheet alloc] initWithTitle:@"Call" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:nil];
    
    // Only add buttons for numbers that are part of the contact
    if ([contactDetails.basic.phone objectForKey:@"home"] != nil && ![[contactDetails.basic.phone objectForKey:@"home"] isEqualToString:@""]) {
        NSString *homeNumber = [NSString stringWithFormat:@"Home: %@", [contactDetails.basic.phone objectForKey:@"home"]];
        [numberActionSheet addButtonWithTitle:homeNumber];
    }
    if ([contactDetails.basic.phone objectForKey:@"work"] != nil && ![[contactDetails.basic.phone objectForKey:@"work"] isEqualToString:@""]) {
        NSString *workNumber = [NSString stringWithFormat:@"Work: %@", [contactDetails.basic.phone objectForKey:@"work"]];
        [numberActionSheet addButtonWithTitle:workNumber];
    }
    if ([contactDetails.basic.phone objectForKey:@"mobile"] != nil && ![[contactDetails.basic.phone objectForKey:@"mobile"] isEqualToString:@""]) {
        NSString *mobileNumber = [NSString stringWithFormat:@"Mobile: %@", [contactDetails.basic.phone objectForKey:@"mobile"]];
        [numberActionSheet addButtonWithTitle:mobileNumber];
    }
    
    [numberActionSheet showInView:contentView];
}

// Grab the contact's lat/long to launch in Apple Maps (wish GoogleMaps was Apple's default map pack)
-(IBAction)launchMaps:(id)sender {

    double latitude = [[contactDetails.address objectForKey:@"latitude"] doubleValue];
    double longitude = [[contactDetails.address objectForKey:@"longitude"] doubleValue];
    
    // If the lat/long were defaulted to 0 in a new contact, don't launch.
    // If we have good values, launch in maps!
    if (latitude != 0.0 || longitude != 0.0) {
        CLLocationCoordinate2D addressCoordinates = CLLocationCoordinate2DMake(latitude, longitude);
        
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:addressCoordinates addressDictionary:nil];
        MKMapItem *item = [[MKMapItem alloc] initWithPlacemark:placemark];
        item.name = [NSString stringWithFormat:@"%@'s address", [self getFirstName:contactDetails.basic.name]];
        [item openInMapsWithLaunchOptions:nil];
    }
}

// As long as we have an email, go ahead and draft an email!
-(IBAction)launchEmail:(id)sender {
    if (![contactDetails.email isEqualToString:@""]) {
        NSString *mailtoString = [NSString stringWithFormat:@"mailto:%@", contactDetails.email];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mailtoString]];
    }
}

// Update "star" image in nav bar as well as contact property for favorite
-(IBAction)toggleFavorite:(id)sender {
    
    if ([contactDetails.favorite boolValue] == YES) {
        contactDetails.favorite = [NSNumber numberWithBool:NO];
        favoriteButton.image = [UIImage imageNamed:@"not-favorite.png"];
    } else {
        contactDetails.favorite = [NSNumber numberWithBool:YES];
        favoriteButton.image = [UIImage imageNamed:@"favorite.png"];
    }
    NSError *error;
    if (![managedObjectContext save:&error]) {
        NSLog(@"Error saving favorite preference: %@", [error localizedDescription]);
    }
}

// Launch the site URL from the button
-(IBAction)launchWebsite:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:contactDetails.website]];
}

#pragma mark - UIActionSheet delegate functions

// This is the action sheet from launching the phone app
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    // Figure out which number was picked
    NSString *whichNumber = [[NSString alloc] init];
    if (buttonIndex == 1) {
        whichNumber = @"home";
    } else if (buttonIndex == 2) {
        whichNumber = @"work";
    } else if (buttonIndex == 3) {
        whichNumber = @"mobile";
    }
    
    // If they pressed cancel, don't call it
    // Otherwise, call the number they picked
    if (buttonIndex != 0) {
        NSString *blankNumber = [[[contactDetails.basic.phone objectForKey:whichNumber] componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
        NSString *numberToCall = [NSString stringWithFormat:@"tel:%@", blankNumber];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:numberToCall]];
    }
}

// Little helper to grab the first name form the full name attribute
-(NSString *)getFirstName:(NSString *)fullName {
    NSArray *firstAndLastName = [fullName componentsSeparatedByString:@" "];
    return firstAndLastName[0];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    // Pass the contact to the edit controller
    if ([segue.identifier isEqualToString:@"fromEdit"]) {
        EditContactViewController *dest = (EditContactViewController *)[segue destinationViewController];
        dest.sourceContactBasic = contactDetails.basic;
        dest.sourceContactDetails = contactDetails;
    }

}

// Unwind segue from editing
- (IBAction)unwindToDetailController:(UIStoryboardSegue *)unwindSegue {
    EditContactViewController *source = (EditContactViewController *) [unwindSegue sourceViewController];
    
    // Save any changes made in the editing view
    NSError* error;
    if(![managedObjectContext save:&error]) {
        NSLog(@"Error saving text field edits: %@", [error localizedDescription]);
    }
    
    // editedTextFields is more or less a bit vector that indicates which fields have been updated
    // 1 is name
    // 2 is company
    // 3 is phones
    // 4 is address
    // 5 is birthday
    // 6 is email
    // 7 is website
    if (source.editedTextFields[1]) {
        NSString* formattedName = [contactDetails.basic.name stringByReplacingOccurrencesOfString:@" " withString:@"\n"];
        nameLabel.text = formattedName;
        
    }
    if (source.editedTextFields[2]) {
        companyLabel.text = contactDetails.basic.company;
    }
    if (source.editedTextFields[3]) {
        homePhoneLabel.text = [contactDetails.basic.phone objectForKey:@"home"];
        workPhoneLabel.text = [contactDetails.basic.phone objectForKey:@"work"];
        mobilePhoneLabel.text = [contactDetails.basic.phone objectForKey:@"mobile"];
    }
    if (source.editedTextFields[4]) {
        NSString *street = [contactDetails.address objectForKey:@"street"];
        NSString *city = [contactDetails.address objectForKey:@"city"];
        NSString *state = [contactDetails.address objectForKey:@"state"];
        NSString *zip = [contactDetails.address objectForKey:@"zip"];
        NSMutableString *rowAddress = [NSMutableString stringWithFormat:@"%@\n%@, %@ %@", street, city, state, zip];
        addressLabel.text = rowAddress;
    }
    if (source.editedTextFields[5]) {
        if (contactDetails.basic.birthdate != nil && ![contactDetails.basic.birthdate isEqualToString:@"0"]) {
            int birthdateInt = [contactDetails.basic.birthdate intValue];
            NSDate *birthdate = [NSDate dateWithTimeIntervalSince1970:birthdateInt];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MMMM d"];
            NSString *formattedDate = [dateFormatter stringFromDate:birthdate];
            birthdateLabel.text = formattedDate;
        } else {
            birthdateLabel.text = @"";
        }
    }
    if (source.editedTextFields[6]) {
        emailLabel.text = contactDetails.email;
    }
    if (source.editedTextFields[7]) {
        [websiteButton setTitle:contactDetails.website forState:UIControlStateNormal];
    }
}

@end
