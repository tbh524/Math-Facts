//
//  poacMFAppDelegate.h
//  poacMF
//
//  Created by Chris Vanderschuere on 3/17/11.
//  Copyright 2011 Chris Vanderschuere. All rights reserved.
/*
	Revision History
	v1.0 (3/17/2011 - ?)
	- 
*/

#import <UIKit/UIKit.h>
#import "User.h"
#import "SPManagedDocument.h"

@interface PoacMFAppDelegate : NSObject <UIApplicationDelegate> {	

}
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong)  SPManagedDocument* documentToSave; //Passed from login to handle saving
@property (nonatomic, strong)	User		*currentUser;


-(void) saveDatabase;

@end
