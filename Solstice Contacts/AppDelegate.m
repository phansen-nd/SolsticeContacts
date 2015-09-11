//
//  AppDelegate.m
//  Solstice Contacts
//
//  Created by Patrick on 7/22/15.
//  Copyright (c) 2015 Patrick Hansen. All rights reserved.
//

#import "AppDelegate.h"
#import "ContactBasic.h"
#import "ContactDetails.h"
#import "ContactsTableViewController.h"

@interface AppDelegate () {
    UILabel *loadingLabel;
}

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Set the All Contacts view's context to the app context
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    ContactsTableViewController *controller = (ContactsTableViewController *)navigationController.topViewController;
    controller.managedObjectContext = self.managedObjectContext;
    
    // If this is the first launch, grab all the default contacts from the endpoint
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
        
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
        ContactsTableViewController *controller = (ContactsTableViewController *)navigationController.topViewController;
        
        // Also, show an activity indicator and put up a load label to let the user know it's loading
        controller.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        controller.activityIndicator.center = controller.view.center;
        [controller.activityIndicator hidesWhenStopped];
        [controller.activityIndicator startAnimating];
        [controller.view addSubview:controller.activityIndicator];
        
        loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(controller.view.center.x - 40, controller.view.center.y - 30, 80, 25)];
        loadingLabel.text = @"Downloading contacts...";
        [loadingLabel sizeToFit];
        loadingLabel.center = controller.view.center;
        [controller.view addSubview:loadingLabel];
        
        // Start getting data in the background
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://solstice.applauncher.com/external/contacts.json"]];
            [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
        });
        
        // Set up employee ID "global"
        [[NSUserDefaults standardUserDefaults] setInteger:21 forKey:@"nextEmployeeID"];

        // Inform that we've passed first launch
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return YES;
}

// Called once the JSON is collected from the endpoint
- (void)fetchedData:(NSData *)responseData {
    
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSError *error;
    NSArray *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    NSEntityDescription *contactBasic = [NSEntityDescription entityForName:@"ContactBasic" inManagedObjectContext:managedObjectContext];
    
    // Get all attributes of a ContactBasic object
    NSDictionary *attributes = [contactBasic attributesByName];
    
    // For every JSON object returned, create a new ContactBasic entity populate it's attributes
    for (int i = 0; i < [json count]; i++) {
        ContactBasic *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"ContactBasic" inManagedObjectContext:managedObjectContext];
        for (NSString *attribute in attributes) {
            id value = [json[i] objectForKey:attribute];
            if (value == nil) {
                continue;
            }
            // Change the format of the phone numbers right away to desired format
            if ([attribute isEqualToString:@"phone"]) {
                NSMutableDictionary *phoneDict = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *) value];
                if ([phoneDict objectForKey:@"mobile"] != nil && ![[phoneDict objectForKey:@"mobile"] isEqualToString:@""]) {
                    [phoneDict setObject:[self parsePhoneNumber:[phoneDict objectForKey:@"mobile"]] forKey:@"mobile"];
                }
                [phoneDict setObject:[self parsePhoneNumber:[phoneDict objectForKey:@"home"]] forKey:@"home"];
                [phoneDict setObject:[self parsePhoneNumber:[phoneDict objectForKey:@"work"]] forKey:@"work"];
                [newItem setValue:phoneDict forKey:attribute];
            } else {
                [newItem setValue:value forKey:attribute];
            }
        }
    }
    
    // Save all the new objects to app context
    if (![managedObjectContext save:&error]) {
        NSLog(@"Error saving basic contacts: %@", [error localizedDescription]);
    }
    
    // Set up a fetch request to load all the basic contacts into the All Contacts view
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSSortDescriptor *nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [fetchRequest setEntity:contactBasic];
    [fetchRequest setSortDescriptors:@[nameDescriptor]];    

    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    ContactsTableViewController *controller = (ContactsTableViewController *)navigationController.topViewController;
    
    controller.contactBasics = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [controller.tableView reloadData];
    
    // Load all of the details too.
    // I originally wanted to leave this until later (e.g. after loading the table view),
    // but I ran into an issue if a contact is selected from the table before all the details are loaded
    // So, we just have to wait a couple extra seconds before we can see anything.. not such a big deal.
    [controller loadContactDetails];
    
    // Data is loaded, stop the spinning gear, start loading contact details
    [controller.activityIndicator stopAnimating];
    [loadingLabel removeFromSuperview];
    
}

// Helper to get our phone numbers how we want them
- (NSString *)parsePhoneNumber:(NSString *)original {
    NSMutableString *new = [NSMutableString stringWithString:original];
    [new insertString:@"(" atIndex:0];
    [new insertString:@")" atIndex:4];
    [new replaceCharactersInRange:NSMakeRange(5, 1) withString:@" "];
    
    NSString *nonmutable = [NSString stringWithString:new];
    return nonmutable;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "self.pat.Solstice_Contacts" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Solstice_Contacts" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Solstice_Contacts.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
