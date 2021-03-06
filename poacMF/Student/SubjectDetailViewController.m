//
//  SubjectDetailViewController.m
//  poacMF
//
//  Created by Chris Vanderschuere on 10/06/2012.
//  Copyright (c) 2012 Chris Vanderschuere. All rights reserved.
//

#import "SubjectDetailViewController.h"
#import "Test.h"
#import "TestSelectCell.h"
#import "StudentGraphPopoverViewController.h"

@interface SubjectDetailViewController ()
@property (nonatomic, strong) NSMutableArray *subjectTests;
@property (nonatomic, strong) UIActionSheet* logoutSheet;
@property (nonatomic, strong) UIPopoverController *resultsPopover;

@property (nonatomic, strong) Test* currentTest;
@end

@implementation SubjectDetailViewController
@synthesize subjectTests = _subjectTests, gridView = _gridView, currentStudent = _currentStudent;
@synthesize logoutSheet = _logoutSheet;
@synthesize resultsPopover = _resultsPopover;
@synthesize currentTest = _currentTest;

-(void) setCurrentStudent:(Student *)currentStudent{
    if (![currentStudent isEqual:_currentStudent]) {
        //Remove old observer
        [[NSNotificationCenter defaultCenter] removeObserver:self  // remove observing of old document (if any)
                                                        name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                      object:_currentStudent.managedObjectContext.persistentStoreCoordinator];

        
        //Update to currentStudent
        _currentStudent = currentStudent;
        
        //Register for iCloud updates
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentContentsChanged:)
                                                     name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                   object:_currentStudent.managedObjectContext.persistentStoreCoordinator];
        
        //Find current test
        self.currentTest = [[currentStudent.tests filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Test* evaluatedObject,NSDictionary* bindings){
            return evaluatedObject.isCurrentTest.boolValue;
        }]] anyObject];
        
        if (self.currentTest)
            [self updateDataForType:self.currentTest.questionSet];
        else {
            self.title =  [NSString stringWithFormat:@"%@: No assigned timings",_currentStudent.username];
        }
    }
}
-(void) updateDataForType: (QuestionSet*) questionSet{
    if (!questionSet)
        return;
    
    //Set title
    self.title = [NSString stringWithFormat:@"%@: %@",self.currentStudent.username,questionSet.typeName];
    
    //Fetch all tests of same type
    NSMutableArray* testsOfSubject = [self.currentStudent.tests filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Test* evaluatedObject,NSDictionary* bindings){
        return [evaluatedObject.questionSet.type isEqualToNumber:questionSet.type];
    }]].allObjects.mutableCopy;
    
    //Sort by sort order
    [testsOfSubject sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"questionSet.difficultyLevel" ascending:YES]]];
    
    //Fetch all question sets of type
    NSFetchRequest *questionSets = [NSFetchRequest fetchRequestWithEntityName:@"QuestionSet"];
    questionSets.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"difficultyLevel" ascending:YES]];
    questionSets.predicate = [NSPredicate predicateWithFormat:@"type == %@",questionSet.type];
    
    NSMutableArray *subjectQuestionSets = [_currentStudent.managedObjectContext executeFetchRequest:questionSets error:NULL].mutableCopy;  
    
    //Replace with tests
    int lastFoundIndex = 0;
    
    for (Test* test in testsOfSubject) {
        //Go thru array one by one and place test... more time consuming than previous method but prevents error when objects not finished saving
        NSUInteger index = [subjectQuestionSets indexOfObjectAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(lastFoundIndex, subjectQuestionSets.count - lastFoundIndex)] options:0 passingTest:^BOOL(QuestionSet* set, NSUInteger idx, BOOL*stop){
            //Only look for question sets
            if ([set isKindOfClass:[Test class]])
                return NO;
            
            if ([set.difficultyLevel isEqualToNumber:test.questionSet.difficultyLevel] && [set.type isEqualToNumber:test.questionSet.type] && [set.name isEqualToString:test.questionSet.name]) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        if (index != NSNotFound){
            [subjectQuestionSets replaceObjectAtIndex:index withObject:test]; //Place Test
            lastFoundIndex = index;
        }
    }
    self.subjectTests = subjectQuestionSets;

}

-(void) setSubjectTests:(NSMutableArray *)subjectTests{
    if (![_subjectTests isEqualToArray:subjectTests]) {
        //Set value and reload data
        _subjectTests = subjectTests;
        [self.gridView reloadData];
    }
}
#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    _emptyCellIndex = NSNotFound;
    
    //Setup Grid View
    // grid view sits on top of the background image
    self.gridView = [[AQGridView alloc] initWithFrame: self.view.bounds];
    self.gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.gridView.backgroundColor = [UIColor clearColor];
    self.gridView.opaque = NO;
    self.gridView.dataSource = self;
    self.gridView.delegate = self;
    self.gridView.scrollEnabled = NO;
    
    if ( UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) )
    {
        // bring 1024 in to 1020 to make a width divisible by five
        self.gridView.leftContentInset = 2.0;
        self.gridView.rightContentInset = 2.0;
    }
    
    [self.view addSubview: self.gridView];
}
-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //Reload with new scores
    [self.gridView reloadData];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}
- (void) willRotateToInterfaceOrientation: (UIInterfaceOrientation) toInterfaceOrientation
                                 duration: (NSTimeInterval) duration
{
    if ( UIInterfaceOrientationIsPortrait(toInterfaceOrientation) )
    {
        // width will be 768, which divides by four nicely already
        NSLog( @"Setting left+right content insets to zero" );
        self.gridView.leftContentInset = 0.0;
        self.gridView.rightContentInset = 0.0;
    }
    else
    {
        // width will be 1024, so subtract a little to get a width divisible by five
        NSLog( @"Setting left+right content insets to 2.0" );
        self.gridView.leftContentInset = 2.0;
        self.gridView.rightContentInset = 2.0;
    }
}
#pragma mark - IBActions
-(IBAction) logOut: (id) sender {
    if (self.logoutSheet.visible)
        return [self.logoutSheet dismissWithClickedButtonIndex:-1 animated:YES];
    
    //2) confirmatory logout prompt if they are logged in
    self.logoutSheet = [[UIActionSheet alloc] initWithTitle:@"Logout?" 
                                                   delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Logout" 
                                          otherButtonTitles:@"Cancel", nil, nil];
    self.logoutSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    self.logoutSheet.delegate = self;
    [self.logoutSheet showFromBarButtonItem:sender animated:YES];
    
    //Save
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SaveDatabase" object:nil]; 
}//end method

#pragma mark - GridView Data Source

- (NSUInteger) numberOfItemsInGridView: (AQGridView *) gridView
{
    return [self.subjectTests count];
}

- (AQGridViewCell *) gridView: (AQGridView *) gridView cellForItemAtIndex: (NSUInteger) index
{
    static NSString * EmptyIdentifier = @"EmptyIdentifier";
    static NSString * CellIdentifier = @"CellIdentifier";
    
    if ( index == _emptyCellIndex )
    {
        NSLog( @"Loading empty cell at index %u", index );
        AQGridViewCell * hiddenCell = [gridView dequeueReusableCellWithIdentifier: EmptyIdentifier];
        if ( hiddenCell == nil )
        {
            // must be the SAME SIZE AS THE OTHERS
            // Yes, this is probably a bug. Sigh. Look at -[AQGridView fixCellsFromAnimation] to fix
            hiddenCell = [[AQGridViewCell alloc] initWithFrame: CGRectMake(0.0, 0.0, 120, 120)
                                               reuseIdentifier: EmptyIdentifier];
        }
        
        hiddenCell.hidden = YES;
        return ( hiddenCell );
    }
        
    id object = [self.subjectTests objectAtIndex:index];

    TestSelectCell * cell = (TestSelectCell *)[gridView dequeueReusableCellWithIdentifier: CellIdentifier];
    if ( cell == nil )
    {
        cell = [[TestSelectCell alloc] initWithFrame: CGRectMake(0.0, 0.0, 120, 120)
                                     reuseIdentifier: CellIdentifier];
    }
    
    if ([object isKindOfClass:[Test class]]) {
        Test *test = object;
        
        cell.name = test.questionSet.name;
        cell.locked = NO;
        
        
        if (test.isCurrentTest.boolValue) {
            //Show highlight
            cell.layer.borderWidth = 3;
            cell.layer.borderColor = [UIColor yellowColor].CGColor;
        }
        else {
            cell.layer.borderWidth = 0;
        }

        //Calculate Pass level
        if (test.results.count>0) {
            int maxCorrect = 0;
            Result *bestResult = nil;
            for (Result* result in test.results) {
                if (result.correctResponses.count>maxCorrect) {
                    maxCorrect = result.correctResponses.count - result.incorrectResponses.count;
                    bestResult = result;
                }
            }
            
            if (bestResult.didPass.boolValue) {
                //Passed
                cell.passedLevel = [NSNumber numberWithInt:1];
            }
            else {
                //Hasn't passed yet
                cell.passedLevel = [NSNumber numberWithInt:0];
            }
        }
        else { //Unattempted
            cell.passedLevel = [NSNumber numberWithInt:-1];
        }

            }
    else{
        //Question Set
        cell.locked = YES;
        cell.name = [object name];
        cell.passedLevel = [NSNumber numberWithInt:-1];
        cell.layer.borderWidth = 0;
    }
    
    return ( cell );
}

- (CGSize) portraitGridCellSizeForGridView: (AQGridView *) gridView
{
    return ( CGSizeMake(142.0, 142.0) );
}
#pragma mark - AQGridView Delegate
-(void) gridView:(AQGridView *)gridView didSelectItemAtIndex:(NSUInteger)index{
    id object = [self.subjectTests objectAtIndex:index];
    if ([object isKindOfClass:[Test class]]) {
        if ([object isCurrentTest].boolValue) {
            //Current Test
            Test *currentTest = (Test*) object;
            UIActionSheet* actionSheet = nil;
            
            //Sort all pracitices and timings by startDate
            NSArray *practices = [[currentTest practice].results.allObjects sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]]];
            NSArray *timings = [currentTest.results.allObjects sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]]];
            
            //Determine if took practice or timing last
            if ([[[practices.lastObject startDate] earlierDate:[timings.lastObject startDate]] isEqualToDate:[timings.lastObject startDate]] || (timings.count == 0 && practices.count != 0)) {
                actionSheet = [[UIActionSheet alloc] initWithTitle:@"Timing"  delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Start Timing",nil];
            }
            else {
                actionSheet = [[UIActionSheet alloc] initWithTitle:@"Practice"  delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Start Practice",nil];
            }
            [actionSheet showFromRect:[gridView rectForItemAtIndex:index]  inView:self.view animated:YES];
        }
        else {
            //Previous test
            [self.gridView deselectItemAtIndex:index animated:YES];
        }
    }
    else if ([object isKindOfClass:[QuestionSet class]]) {
        [self.gridView deselectItemAtIndex:index animated:YES];
    }
}
#pragma mark - UIActionSheet Delegate
-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if ([actionSheet.title isEqualToString:@"Logout?"]) {
        if (buttonIndex == 0) {
            [self.resultsPopover dismissPopoverAnimated:YES];
            [self.parentViewController dismissViewControllerAnimated:YES completion:NULL];
        }
    }
    else {
        if ([actionSheet.title isEqualToString:@"Timing"] && buttonIndex != -1) {
            //Launch Test
            [self performSegueWithIdentifier:@"startTestSegue" sender:self.gridView];
        }
        else if ([actionSheet.title isEqualToString:@"Practice"] && buttonIndex != -1) {
            //Launch Practice
            [self performSegueWithIdentifier:@"startPracticeSegue" sender:self.gridView];
        }
        [self.gridView deselectItemAtIndex:self.gridView.selectedIndex animated:YES];
    }
}

#pragma mark - Storyboard
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"startTestSegue"]) {
        //Pass test to TestVC
        Test *selectedTest = [self.subjectTests objectAtIndex:[sender selectedIndex]];
        NSLog(@"Selected Test: %@",selectedTest.questionSet.name);
        [segue.destinationViewController setDelegate:self];
        [segue.destinationViewController setTest:selectedTest];
    }
    else if ([segue.identifier isEqualToString:@"startPracticeSegue"]) {
        //Pass test to TestVC
        Test *selectedTest = [self.subjectTests objectAtIndex:[sender selectedIndex]];
        [segue.destinationViewController setDelegate:self];
        [segue.destinationViewController setPractice:selectedTest.practice];
    }

}
#pragma mark - Test Result Delegate
-(void) didFinishTest:(Test*)finishedTest withResult:(Result*)result{

    BOOL passed = result.didPass.boolValue;
    
    if (passed) {
        //Find next questionSet to create new test
        NSFetchRequest *nextQSFetch = [NSFetchRequest fetchRequestWithEntityName:@"QuestionSet"];
        nextQSFetch.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES selector:@selector(compare:)],[NSSortDescriptor sortDescriptorWithKey:@"difficultyLevel" ascending:YES selector:@selector(compare:)],[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)],nil];
        nextQSFetch.predicate = [NSPredicate predicateWithFormat:@"(type == %@ AND difficultyLevel > %@) OR type > %@",finishedTest.questionSet.type,finishedTest.questionSet.difficultyLevel,finishedTest.questionSet.type];
        nextQSFetch.fetchBatchSize = 1;
        
        NSArray* nextQs = [self.currentStudent.managedObjectContext executeFetchRequest:nextQSFetch error:NULL];
        if (nextQs.count >0) {
            QuestionSet *nextQuestionSet = [nextQs objectAtIndex:0];
            [self.currentStudent selectQuestionSet:nextQuestionSet];
            [self updateDataForType:nextQuestionSet];
        }
        else {
            //No more question sets
            [self.currentStudent setCurrentTest:nil];
        }
        
    }
        
    //Create UIAlertView to present information
    UIAlertView *finishedTestAlert = [[UIAlertView alloc] initWithTitle:passed?@"You Passed!":@"Try the Practice Again" 
                                                                message:passed?[NSString stringWithFormat:@"You got %d correct and %d incorrect.",result.correctResponses.count,result.incorrectResponses.count]:[NSString stringWithFormat:@"To pass you need %d correct and can only get %d incorrect.",finishedTest.passCriteria.intValue,finishedTest.maximumIncorrect.intValue]
                                                               delegate:nil 
                                                      cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [finishedTestAlert show];
}



- (void)viewDidUnload {
    [super viewDidUnload];
}
- (IBAction)showResultsGraph:(id)sender {
    if (self.resultsPopover.popoverVisible) {
        [self.resultsPopover dismissPopoverAnimated:YES];
    }
    else {        
        StudentGraphPopoverViewController *graphVC = [self.storyboard instantiateViewControllerWithIdentifier:@"StudentGraphPopoverViewController"];
        graphVC.resultsArray = self.currentStudent.results.allObjects;
        
        self.resultsPopover = [[UIPopoverController alloc] initWithContentViewController:graphVC];
        [self.resultsPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    
}
#pragma mark - iCloud
- (void)documentContentsChanged:(NSNotification *)notification
{
    [self.currentStudent.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    
    //Update UI
    //Find current test
    Test* currentTest = [[self.currentStudent.tests filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Test* evaluatedObject,NSDictionary* bindings){
        return evaluatedObject.isCurrentTest.boolValue;
    }]] anyObject];
    
    if (![currentTest isEqual:self.currentTest]) {
        //Current test has changed
        self.currentTest = currentTest;
        
        //Update UI=]
        if (self.currentTest)
            [self updateDataForType:self.currentTest.questionSet];
        else {
            self.title = @"No assigned timings";
        }
    }
    
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
