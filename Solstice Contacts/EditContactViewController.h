//
//  EditContactViewController.h
//  Solstice Contacts
//
//  Created by Patrick on 7/25/15.
//  Copyright (c) 2015 Patrick Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactBasic.h"
#import "ContactDetails.h"

@interface EditContactViewController : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) IBOutlet UITextField *companyTextField;
@property (nonatomic, weak) IBOutlet UITextField *firstNameTextField;
@property (nonatomic, weak) IBOutlet UITextField *lastNameTextField;
@property (nonatomic, weak) IBOutlet UIImageView *headshotImageView;
@property (nonatomic, weak) IBOutlet UITextField *homeNumberTextField;
@property (nonatomic, weak) IBOutlet UITextField *workNumberTextField;
@property (nonatomic, weak) IBOutlet UITextField *mobileNumberTextField;
@property (nonatomic, weak) IBOutlet UITextField *emailTextField;
@property (nonatomic, weak) IBOutlet UITextField *websiteTextField;
@property (nonatomic, weak) IBOutlet UITextField *streetTextField;
@property (nonatomic, weak) IBOutlet UITextField *zipTextField;
@property (nonatomic, weak) IBOutlet UITextField *cityTextField;
@property (nonatomic, weak) IBOutlet UITextField *stateTextField;
@property (nonatomic, weak) IBOutlet UITextField *birthdayTextField;
@property (nonatomic, weak) IBOutlet UIButton *doneEditingButton;
@property (nonatomic, weak) IBOutlet UIButton *addContactButton;
@property (nonatomic, weak) IBOutlet UIButton *takePictureButton;
@property (nonatomic, weak) IBOutlet UIView *contentView;

@property NSMutableArray *editedTextFields;

@property ContactBasic *sourceContactBasic;
@property ContactDetails *sourceContactDetails;
@property NSData *pictureData;
@property NSManagedObjectContext *managedObjectContext;

-(IBAction)takePhoto:(id)sender;
-(IBAction)cancelClicked:(id)sender;

@end
