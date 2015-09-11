//
//  ContactsTableViewController.m
//  
//
//  Created by Patrick on 7/23/15.
//
//

#import "ContactsTableViewController.h"
#import "ContactBasic.h"
#import "ContactDetails.h"
#import "ContactTableViewCell.h"
#import "ContactDetailViewController.h"
#import "EditContactViewController.h"

@interface ContactsTableViewController () {
    BOOL showingFavorites;
}

@end

@implementation ContactsTableViewController

@synthesize managedObjectContext;
@synthesize contactBasics;
@synthesize activityIndicator;
@synthesize listIndicator;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Take care of some initializations
    self.title = @"All Contacts";
    showingFavorites = NO;
    
    // Reload data from Persistent Store and then reload table
    [self reloadDataFromStore];
    [self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
}

// Grab all of the contacts from the Persistent Store and store in array contactBasics
- (void) reloadDataFromStore {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSSortDescriptor *nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSEntityDescription *contactBasic = [NSEntityDescription entityForName:@"ContactBasic" inManagedObjectContext:managedObjectContext];
    NSError *error;
    
    [fetchRequest setEntity:contactBasic];
    [fetchRequest setSortDescriptors:@[nameDescriptor]];
    
    contactBasics = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
}

// Load all of the details from contacts
- (void)loadContactDetails {

    NSError *error;
    NSEntityDescription *contactBasic = [NSEntityDescription entityForName:@"ContactBasic" inManagedObjectContext:managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:contactBasic];
    NSArray *tempContactBasics = [managedObjectContext executeFetchRequest:fetchRequest error:&error];

    if (error) {
        NSLog(@"Ah man, couldn't fetch the default contacts: %@", [error localizedDescription]);
    }
    
    // Get all attributes of a ContactDetails object
    NSEntityDescription *contactDetails = [NSEntityDescription entityForName:@"ContactDetails" inManagedObjectContext:managedObjectContext];
    NSDictionary *attributes = [contactDetails attributesByName];
    
    // For each default contact that was downloaded, grab the details JSON
    for (ContactBasic *defaultContact in tempContactBasics) {
        NSURL *detailsURL = [NSURL URLWithString:defaultContact.detailsURL];
        NSData *responseData = [NSData dataWithContentsOfURL:detailsURL];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];

        // Create a new ContactDetails object
        ContactDetails *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"ContactDetails" inManagedObjectContext:managedObjectContext];
        
        // Set all the ContactDetails attributes available in JSON
        for (NSString *attribute in attributes) {
            id value = [json objectForKey:attribute];
            if (value == nil) {
                continue;
            }
            [newItem setValue:value forKey:attribute];
        }
        
        // Grab the big image for local store (it's still not that big)
        NSURL *largeImageURL = [NSURL URLWithString:newItem.largeImageURL];
        NSData *largeImageData = [NSData dataWithContentsOfURL:largeImageURL];
        if (largeImageData) {
            newItem.largeImageData = largeImageData;
        }
        
        // Set the ContactDetails and ContactBasic relationship
        newItem.basic = defaultContact;
        defaultContact.details = newItem;
    }
    
    // Try saving all the new objects to app context
    if (![managedObjectContext save:&error]) {
        NSLog(@"Loading details save error: %@", [error localizedDescription]);
    }
}

#pragma mark - button actions

// Alternate between showing all contacts and just favorites
-(IBAction)toggleContactList:(id)sender {
    
    // Fetch request for all ContactBasic objects
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSSortDescriptor *nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSEntityDescription *contactBasic = [NSEntityDescription entityForName:@"ContactBasic" inManagedObjectContext:managedObjectContext];
    NSError *error;
    
    // Sort alphabetically
    [fetchRequest setEntity:contactBasic];
    [fetchRequest setSortDescriptors:@[nameDescriptor]];
    
    // Switch the necessary variables/strings
    if (showingFavorites) {
        [listIndicator setTitle:@"Favorites"];
        self.title = @"All Contacts";
        showingFavorites = NO;
    } else {
        [listIndicator setTitle:@"All Contacts"];
        self.title = @"Favorites";
        showingFavorites = YES;
        
        // If we're querying for favorites, set up the proper predicate
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"details.favorite == YES"];
        [fetchRequest setPredicate:predicate];
    }

    // Update the array that populates the table view and reload
    contactBasics = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [contactBasics count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"ContactTableCell";
    ContactTableViewCell *cell = (ContactTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
 
    // Init cells with my custom XIB
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ContactTableCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    // Access the contact that was touched
    ContactBasic *contact = [contactBasics objectAtIndex:indexPath.row];
    
    // Access the phone numbers in a dictionary so one can be displayed in the table cell
    NSDictionary *phoneDict = [NSDictionary dictionaryWithDictionary:contact.phone];

    // If we don't have the small image downloaded, put in a default and download it!
    if (contact.smallImageData == nil) {
        cell.thumbnailImageView.image = [UIImage imageNamed:@"thumbnail-placeholder.jpg"];
        
        // In the background, download the small image data, set the image, and store the data in-app
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:contact.smallImageURL]];
            if (data) {
                contact.smallImageData = data;
                UIImage *image = [UIImage imageWithData:data];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSError *error;
                        if(![managedObjectContext save:&error]) {
                            NSLog(@"Loading thumbnail image error: %@", [error localizedDescription]);
                        }
                        cell.thumbnailImageView.image = image;
                    });
                }
            }
        });
        
    } else {
        // If we already have the data, just populate it
        cell.thumbnailImageView.image = [UIImage imageWithData:contact.smallImageData];
    }
    
    // Also give the table cell the contact name and phone of the phone numbers (mobile if available, home otherwise)
    cell.nameLabel.text = contact.name;
    if (([phoneDict objectForKey:@"mobile"] == nil) || [[phoneDict objectForKey:@"mobile"] isEqualToString:@""]) {
        cell.phoneLabel.text = [phoneDict objectForKey:@"home"];
    } else {
        cell.phoneLabel.text = [phoneDict objectForKey:@"mobile"];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Perform segue to show contact's details in new view
    [self performSegueWithIdentifier:@"showContactDetail" sender:[contactBasics objectAtIndex:indexPath.row]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // If we're about to show a contact's details, send it the contact that was chosen
    if ([[segue identifier] isEqualToString:@"showContactDetail"]) {
        UINavigationController *navigationController = (UINavigationController *)[segue destinationViewController];
        ContactDetailViewController *dest = (ContactDetailViewController *)[navigationController topViewController];
        ContactBasic *contactSender = (ContactBasic *)sender;
        dest.contactDetails = contactSender.details;
        
    }
}

// Unwind segue triggered after a new contact is added
- (IBAction)unwindToTableViewController:(UIStoryboardSegue *)unwindSegue {

    // Get the source controller
    EditContactViewController *source = (EditContactViewController *) [unwindSegue sourceViewController];
    
    // Create new ContactBasic and ContactDetails objects
    ContactBasic *newContactBasic = [NSEntityDescription insertNewObjectForEntityForName:@"ContactBasic" inManagedObjectContext:managedObjectContext];
    ContactDetails *newContactDetails = [NSEntityDescription insertNewObjectForEntityForName:@"ContactDetails" inManagedObjectContext:managedObjectContext];
    
    // Set the name and company
    newContactBasic.name = [NSString stringWithFormat:@"%@ %@", source.firstNameTextField.text, source.lastNameTextField.text];
    newContactBasic.company = source.companyTextField.text;
    
    // Set up the phone dictionary
    NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
    [newDict setObject:source.homeNumberTextField.text forKey:@"home"];
    [newDict setObject:source.workNumberTextField.text forKey:@"work"];
    [newDict setObject:source.mobileNumberTextField.text forKey:@"mobile"];
    newContactBasic.phone = newDict;
    
    // Get the next available employee ID and update the stored variable
    NSNumber *nextID = [[NSUserDefaults standardUserDefaults] objectForKey:@"nextEmployeeID"];
    newContactBasic.employeeId = nextID;
    newContactDetails.employeeId = nextID;
    int nextIDint = [nextID intValue];
    NSNumber *updatedNextID = [NSNumber numberWithInt:(nextIDint + 1)];
    [[NSUserDefaults standardUserDefaults] setObject:updatedNextID forKey:@"nextEmployeeID"];
    
    // Set up favoriteness (default to false), email, and website
    newContactDetails.favorite = [NSNumber numberWithBool:NO];
    newContactDetails.website = source.websiteTextField.text;
    newContactDetails.email = source.emailTextField.text;
    
    // Set up the address
    NSMutableDictionary *otherNewDict = [[NSMutableDictionary alloc] init];
    [otherNewDict setObject:source.streetTextField.text forKey:@"street"];
    [otherNewDict setObject:source.cityTextField.text forKey:@"city"];
    [otherNewDict setObject:source.stateTextField.text forKey:@"state"];
    [otherNewDict setObject:source.zipTextField.text forKey:@"zip"];
    newContactDetails.address = otherNewDict;
    
    // Set up birthday
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM d"];
    NSDate *birthdayDate = [dateFormatter dateFromString:source.birthdayTextField.text];
    newContactBasic.birthdate = [NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:[birthdayDate timeIntervalSince1970]]];
    
    // Set up the inverse relationship
    newContactBasic.details = newContactDetails;
    newContactDetails.basic = newContactBasic;
    
    // Give the default picture if a picture wasn't uploaded
    if (source.pictureData == nil) {
        NSData *headshotImageData = UIImageJPEGRepresentation([UIImage imageNamed:@"headshot-placeholder.jpg"], 0.7);
        newContactDetails.largeImageData = headshotImageData;
    } else {
        newContactBasic.smallImageData = source.pictureData;
        newContactDetails.largeImageData = source.pictureData;
    }
    
    
    // Give saving a shot
    NSError *error;
    if (![managedObjectContext save:&error]) {
        NSLog(@"Whoops, error: %@", [error localizedDescription]);
    }
    
    // Reload the array that populates the table and reload the table
    [self reloadDataFromStore];
    [self.tableView reloadData];
}


@end
