//
//  EditContactViewController.m
//  Solstice Contacts
//
//  Created by Patrick on 7/25/15.
//  Copyright (c) 2015 Patrick Hansen. All rights reserved.
//

#import "EditContactViewController.h"
#import "AppDelegate.h"

static const CGFloat KEYBOARD_ANIMATION_DURATION = 0.3;
static const CGFloat MINIMUM_SCROLL_FRACTION = 0.2;
static const CGFloat MAXIMUM_SCROLL_FRACTION = 0.8;
static const CGFloat PORTRAIT_KEYBOARD_HEIGHT = 216;
static const CGFloat LANDSCAPE_KEYBOARD_HEIGHT = 162;

@interface EditContactViewController () {
    CGFloat animatedDistance;
}

@end

@implementation EditContactViewController

@synthesize companyTextField;
@synthesize firstNameTextField;
@synthesize lastNameTextField;
@synthesize headshotImageView;
@synthesize homeNumberTextField;
@synthesize workNumberTextField;
@synthesize mobileNumberTextField;
@synthesize emailTextField;
@synthesize websiteTextField;
@synthesize streetTextField;
@synthesize zipTextField;
@synthesize cityTextField;
@synthesize stateTextField;
@synthesize birthdayTextField;
@synthesize addContactButton;
@synthesize doneEditingButton;
@synthesize takePictureButton;
@synthesize contentView;

@synthesize editedTextFields;

@synthesize sourceContactBasic;
@synthesize sourceContactDetails;
@synthesize managedObjectContext;
@synthesize pictureData;

- (void)viewDidLoad {
    [super viewDidLoad];

    // Nifty setting to set scrollView up below nav bar but allow it to scroll behind it
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // Set the context
    managedObjectContext = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    // Set all the text fields' delegates to the view
    companyTextField.delegate = self;
    firstNameTextField.delegate = self;
    lastNameTextField.delegate = self;
    homeNumberTextField.delegate = self;
    workNumberTextField.delegate = self;
    mobileNumberTextField.delegate = self;
    emailTextField.delegate = self;
    emailTextField.keyboardType = UIKeyboardTypeEmailAddress; // Give email the custom keyboard
    websiteTextField.delegate = self;
    streetTextField.delegate = self;
    zipTextField.delegate = self;
    cityTextField.delegate = self;
    stateTextField.delegate = self;
    birthdayTextField.delegate = self;
    
    // Set the edited array (bit vector) to all false
    editedTextFields = [[NSMutableArray alloc] initWithCapacity:8];
    for (int i = 0; i < 8; i++) {
        [editedTextFields addObject:[NSNumber numberWithBool:NO]];
    }
    
    // Came from editing an existing contact, prepopulate text fields
    if (sourceContactBasic != nil) {
        
        // Hide/show the right buttons
        // We have two different buttons to exit this view,
        // one returns to Contact Details, the other to All Contacts
        doneEditingButton.hidden = NO;
        addContactButton.hidden = YES;
        takePictureButton.hidden = YES;
        NSArray *firstAndLastName = [sourceContactBasic.name componentsSeparatedByString:@" "];
        
        // Company, name, phones, email, website
        companyTextField.text = sourceContactBasic.company;
        firstNameTextField.text = firstAndLastName[0];
        lastNameTextField.text = firstAndLastName[1];
        headshotImageView.image = [UIImage imageWithData:sourceContactDetails.largeImageData];
        homeNumberTextField.text = [sourceContactBasic.phone objectForKey:@"home"];
        workNumberTextField.text = [sourceContactBasic.phone objectForKey:@"work"];
        mobileNumberTextField.text = [sourceContactBasic.phone objectForKey:@"mobile"];
        emailTextField.text = sourceContactDetails.email;
        websiteTextField.text = sourceContactDetails.website;
        
        // Address
        streetTextField.text = [sourceContactDetails.address objectForKey:@"street"];
        cityTextField.text = [sourceContactDetails.address objectForKey:@"city"];
        stateTextField.text = [sourceContactDetails.address objectForKey:@"state"];
        zipTextField.text = [sourceContactDetails.address objectForKey:@"zip"];
        
        // Birthday
        if (sourceContactBasic.birthdate != nil && ![sourceContactBasic.birthdate isEqualToString:@"0"]) {
            int birthdateInt = [sourceContactDetails.basic.birthdate intValue];
            NSDate *birthdate = [NSDate dateWithTimeIntervalSince1970:birthdateInt];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MMMM d"];
            NSString *formattedDate = [dateFormatter stringFromDate:birthdate];
            birthdayTextField.text = formattedDate;
        }
        
        
    // Came from contacts, adding a brand new contact
    } else {
        doneEditingButton.hidden = YES;
        addContactButton.hidden = NO;
        takePictureButton.hidden = NO;
    }
    
}

// Cancel clicked, exit this view without saving anything
-(IBAction)cancelClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Called when "Take Picture" button is clicked, starts the camera
-(IBAction)takePhoto:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - UIImagePicker delegate functions

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];

    // Set the image taken to the Contact Detail image
    headshotImageView.image = chosenImage;
    
    // Save the image data so it can be added to the contact later
    pictureData = UIImageJPEGRepresentation(chosenImage, 0.7);
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Text Field delegate functions

// Hide keyboard when return is pressed
-(BOOL) textFieldShouldReturn: (UITextField *) textField {
    [textField resignFirstResponder];
    return YES;
}

// Got this implementation of the delegate method from www.cocoawithlove.com
// to make sure the keyboard doesn't hide the text field to be edited.
// Thanks to Matt Gallagher at Cocoa With Love!
-(void) textFieldDidBeginEditing:(UITextField *)textField {
    CGRect textFieldRect = [self.view.window convertRect:textField.bounds fromView:textField];
    CGRect viewRect = [self.view.window convertRect:self.view.bounds fromView:self.view];
    
    CGFloat midline = textFieldRect.origin.y + 0.5 * textFieldRect.size.height;
    CGFloat numerator = midline - viewRect.origin.y - MINIMUM_SCROLL_FRACTION * viewRect.size.height;
    CGFloat denominator = (MAXIMUM_SCROLL_FRACTION - MINIMUM_SCROLL_FRACTION) * viewRect.size.height;
    CGFloat heightFraction = numerator / denominator;
    if (heightFraction < 0.0) {
        heightFraction = 0.0;
    }
    else if (heightFraction > 1.0) {
        heightFraction = 1.0;
    }
    
    UIInterfaceOrientation orientation =
    [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        animatedDistance = floor(PORTRAIT_KEYBOARD_HEIGHT * heightFraction);
    }
    else {
        animatedDistance = floor(LANDSCAPE_KEYBOARD_HEIGHT * heightFraction);
    }
    
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y -= animatedDistance;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [self.view setFrame:viewFrame];
    
    [UIView commitAnimations];
}

// If we're editing a contact, save potential changes in the context right away
-(void) textFieldDidEndEditing:(UITextField *) textField {
    if (sourceContactBasic != nil) {
        
        switch (textField.tag) {
            // Tag 1 is name (first and last)
            case 1: {
                NSString *newName = [NSString stringWithFormat:@"%@ %@", firstNameTextField.text, lastNameTextField.text];
                if (newName != sourceContactBasic.name) {
                    sourceContactBasic.name = newName;
                }
                break;
            }
            // Tag 2 is company
            case 2:
                if (textField.text != sourceContactBasic.company) {
                    sourceContactBasic.company = textField.text;
                }
            // Tag 3 is phone numbers (all)
            case 3: {
                NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:sourceContactBasic.phone];
                [newDict setObject:homeNumberTextField.text forKey:@"home"];
                [newDict setObject:workNumberTextField.text forKey:@"work"];
                [newDict setObject:mobileNumberTextField.text forKey:@"mobile"];
                sourceContactBasic.phone = newDict;
                break;
            }
            // Tag 4 is address
            case 4: {
                NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:sourceContactDetails.address];
                [newDict setObject:streetTextField.text forKey:@"street"];
                [newDict setObject:cityTextField.text forKey:@"city"];
                [newDict setObject:stateTextField.text forKey:@"state"];
                [newDict setObject:zipTextField.text forKey:@"zip"];
                sourceContactDetails.address = newDict;
                break;
            }
            // Tag 5 is birthday
            case 5: {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"MMMM d"];
                NSDate *birthdayDate = [dateFormatter dateFromString:birthdayTextField.text];
                sourceContactDetails.basic.birthdate = [NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:[birthdayDate timeIntervalSince1970]]];
                break;
            }
            // Tag 6 is email
            case 6:
                if (textField.text != sourceContactDetails.email) {
                    sourceContactDetails.email = textField.text;
                }
            // Tag 7 is website
            case 7:
                if (textField.text != sourceContactDetails.website) {
                    sourceContactDetails.website = textField.text;
                }
            
            default:
                break;
        }
        
        // Update the edited array to reflect changes
        editedTextFields[textField.tag] = [NSNumber numberWithBool:YES];
        
        // We won't save any changes until the user clicks "Done editing"
        // in case the user clicks "Cancel" before then
        // For now, the changes will just sit in the context, waiting to be stored
    }
    
    // Put the text field back (help from Cocoa With Love!)
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y += animatedDistance;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [self.view setFrame:viewFrame];
    
    [UIView commitAnimations];
}

@end
