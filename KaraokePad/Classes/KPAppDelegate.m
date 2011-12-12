//
//  KPAppDelegate.m
//  KaraokePad
//
//  Created by Michael Potter on 11/28/11.
//  Copyright (c) 2011 LucasTizma. All rights reserved.
//

#import "KPAppDelegate.h"

#pragma mark Class Extension -

@interface KPAppDelegate ()

@property (readwrite, nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (readwrite, nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (readwrite, nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, nonatomic, strong) NSURL *applicationDocumentsDirectory;

- (void)saveContext;

@end

@implementation KPAppDelegate

@synthesize window;
@synthesize managedObjectContext;
@synthesize managedObjectModel;
@synthesize persistentStoreCoordinator;

#pragma mark - Property Accessors

- (NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext != nil)
    {
        return managedObjectContext;
    }

    if (self.persistentStoreCoordinator != nil)
    {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    }

    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel != nil)
    {
        return managedObjectModel;
    }

    NSURL *managedObjectModelURL = [[NSBundle mainBundle] URLForResource:@"KaraokePad" withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:managedObjectModelURL];

    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil)
    {
        return persistentStoreCoordinator;
    }

    NSURL *persistentStoreCoordinatorURL = [self.applicationDocumentsDirectory URLByAppendingPathComponent:@"KaraokePad.sqlite"];

	NSDictionary *persistentStoreCoordinatorOptions = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
		[NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
		nil];

    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];

    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:persistentStoreCoordinatorURL
		options:persistentStoreCoordinatorOptions error:nil])
    {
        NSLog(@"Core Data error, most likely a model migration issue.");
        abort();
    }

    return persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory
{
	return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Private Methods

- (void)saveContext
{
    if (self.managedObjectContext != nil)
    {
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:nil])
        {
            NSLog(@"Error saving the managed object context.");
            abort();
        }
    }
}

#pragma mark - Protocol Implementations

#pragma mark - UIApplicationDelegate Methods

- (void)applicationWillTerminate:(UIApplication *)application
{
	[self saveContext];
}

@end