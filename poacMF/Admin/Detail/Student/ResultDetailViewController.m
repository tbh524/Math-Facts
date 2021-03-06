//
//  ResultDetailViewController.m
//  poacMF
//
//  Created by Chris Vanderschuere on 15/06/2012.
//  Copyright (c) 2012 Chris Vanderschuere. All rights reserved.
//

#import "ResultDetailViewController.h"
#import "Question.h"
#import "QuestionSet.h"
#import "Test.h"
#import "Practice.h"

@interface ResultDetailViewController ()

@property (nonatomic, strong) NSMutableArray *questionsCorrect;
@property (nonatomic, strong) NSMutableArray *questionsIncorrect;

@end

@implementation ResultDetailViewController
@synthesize result = _result;
@synthesize questionsCorrect = _questionsCorrect, questionsIncorrect = _questionsIncorrect;

-(void) setResult:(Result *)result{
    _result = result;
    
    //Set title
    Test *test = result.isPractice.boolValue?result.practice.test:result.test;
    self.title = [NSString stringWithFormat:@"%@ (%@): %@",test.questionSet.typeName,test.questionSet.name,[NSDateFormatter localizedStringFromDate:_result.startDate dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle]];
    
    //Reload data
    self.questionsCorrect = _result.correctResponses.allObjects.mutableCopy;
    self.questionsIncorrect = _result.incorrectResponses.allObjects.mutableCopy;
    
    //Sort data
    [self.questionsCorrect sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]];
    [self.questionsIncorrect sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]];

    
    [self.tableView reloadData];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            return self.questionsCorrect.count;
            break;
        case 1:
            return self.questionsIncorrect.count;
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"resultQuestionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    Response *response = indexPath.section == 0?[self.questionsCorrect objectAtIndex:indexPath.row]:[self.questionsIncorrect objectAtIndex:indexPath.row];
    
    //Format for question
    if (response.question.questionSet) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ %@ = %@",response.question.x?response.question.x.stringValue:@"__",response.question.questionSet.typeSymbol,response.question.y?response.question.y.stringValue:@"__",response.question.z?response.question.z.stringValue:@"__"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", response.answer, response.question.questionSet.name];
    }
    else {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ ? %@ = %@",response.question.x?response.question.x.stringValue:@"__",response.question.y?response.question.y.stringValue:@"__",response.question.z?response.question.z.stringValue:@"__"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (Deleted Question)", response.answer];
    }
    return cell;
}
-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return [NSString stringWithFormat:@"Questions Correct: %d",self.result.correctResponses.count];
            break;
        case 1:
            return [NSString stringWithFormat:@"Questions Incorrect: %d",self.result.incorrectResponses.count];
        default:
            return nil;
            break;
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

@end
