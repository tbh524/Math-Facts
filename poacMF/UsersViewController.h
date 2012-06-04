//
//  UsersTableViewController.h
//  poacMF
//
//  Created by Matt Hunter on 3/24/11.
//  Copyright 2011 Matt Hunter. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UsersViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate> {
	NSMutableArray			*__weak listOfUsers;
	UITableView				*__weak thisTableView;
    
}

@property (weak, nonatomic)				NSMutableArray			*listOfUsers;
@property (weak, nonatomic)	IBOutlet	UITableView				*thisTableView;

-(IBAction) setEditableTable;
-(IBAction)	userTableEditingTapped;
-(IBAction)	assignQuizTapped;
-(IBAction)	assignTestTapped;
-(IBAction) addUser: (id) sender;
-(void)		quizButtonClicked: (id) sender;

@end
