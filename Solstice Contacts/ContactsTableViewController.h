//
//  ContactsTableViewController.h
//  
//
//  Created by Patrick on 7/23/15.
//
//

#import <UIKit/UIKit.h>

@interface ContactsTableViewController : UITableViewController

@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic,strong) NSArray *contactBasics;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *listIndicator;

-(void)loadContactDetails;

-(IBAction)toggleContactList:(id)sender;

@end
