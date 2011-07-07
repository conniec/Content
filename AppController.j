/*
 * AppController.j
 * Content Tool
 *
 * Created by ofosho on November 10, 2010.
 * Copyright 2010, OTech Engineering Inc All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPView.j>
@import "FilterBar.j"
@import "WordDataSource.j"
@import "GroupDataSource.j"
@import "globals.j"
@import "ToolbarDelegate.j"
@import "WordsController.j"
@import "WordListView.j"
@import "WordItemView.j"
@import "Word.j"


@end

@implementation AppController : CPObject
{
	CPSplitView verticalSplitter;
	CPView scrollParentView;
	CPView leftView;
	CPView rightView;
	CPSearchField searchField;
	CPTableView tableView;
	CPTableView groupView;
	CPScrollView scrollView;
	CPScrollView groupScrollView;
	CPToolbar toolbar;
	WordsController wordsController;
	WordDataSource wordDS;
	GroupDataSource groupDS;
	JSObject headerColor;
	FilterBar   filterBar;
}
- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
	var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
		contentView = [theWindow contentView];

	wordDS = [[WordDataSource alloc] init];
	groupDS = [[GroupDataSource alloc] init];
	wordsController = [[WordsController alloc] init];

	toolbar = [[CPToolbar alloc] initWithIdentifier:"Words"];
	var toolbarDelegate = [[ToolbarDelegate alloc] init];
	[toolbarDelegate setWordsController:wordsController];
	[toolbar setDelegate:toolbarDelegate];
	[toolbar setVisible:YES];
	[theWindow setToolbar:toolbar];


	[self initNotifications];	
	[self createSearchField];
	[self splitPage:[contentView bounds]];
	[self createGroupView];
	[self createListView];

	[self combineViews];
	
	// add vertical splitter (entire page) to contentview
	[contentView addSubview:verticalSplitter];

	[CPMenu setMenuBarVisible: YES]
	//[self createMenu];
	[theWindow orderFront:self];
}
- (void)initNotifications
{
	[[CPNotificationCenter defaultCenter ]
            addObserver:self
               selector:@selector(reloadGroups:)
                   name:reloadGroupsNoti
                 object:nil];
				 
	[[CPNotificationCenter defaultCenter ]
            addObserver:self
               selector:@selector(reloadTable:)
                   name:reloadTableNoti
                 object:nil];
				 
	[[CPNotificationCenter defaultCenter ]
            addObserver:self
               selector:@selector(addColumns:)
                   name:addColumnsNoti 
                 object:nil];

	[[CPNotificationCenter defaultCenter ]
            addObserver:self
               selector:@selector(showFilterBar:)
                   name:showFilterBarNoti
                 object:nil];
				 
	[[CPNotificationCenter defaultCenter ]
            addObserver:self
               selector:@selector(hideFilterBar:)
                   name:hideFilterBarNoti
                 object:nil];
}


- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
	if(groupView === [aNotification object]){
		var i = [[[aNotification object] selectedRowIndexes] firstIndex];
		[wordsController getWord:[[groupDS objs] objectAtIndex:i]];
		[searchField setStringValue:@""];
		[self hideFilterBar:nil];
	}
	else{
		var i = [[[aNotification object] selectedRowIndexes] firstIndex];
		if(i > -1){
			var row = [[wordsController objsToDisplay] objectAtIndex:i];
		}
	}
}

- (void)reloadTable:(CPNotification)aNotification
{	
    [tableView reloadData];	
}

- (void)reloadGroups:(CPNotification)aNotification
{	
    [groupView reloadData];	
}

- (void)hideFilterBar:(CPNotification)aNotification
{
    if (![filterBar superview])
        return;

    [filterBar removeFromSuperview];

    var frame = [scrollView frame];
    frame.origin.y = 0;
    frame.size.height += 32;
	
    [scrollView setFrame:frame];
}
- (void)showFilterBar:(CPNotification)aNotification
{
    if ([filterBar superview])
        return;

    [filterBar setFrame:CGRectMake(0, 0, CGRectGetWidth([scrollParentView frame]), 32)];
    [scrollParentView addSubview:filterBar];

    var frame = [scrollView frame];
    frame.origin.y = 32;
    frame.size.height -= 32;
	
    [scrollView setFrame:frame];
}

- (void)addColumns:(CPNotification)aNotification
{
	for(var i=0;i < [[wordsController columnHeaders] count];i++){
		var headerKey = [[wordsController columnHeaders] objectAtIndex:i];
		var desc = [CPSortDescriptor sortDescriptorWithKey:headerKey ascending:NO];
		var column = [[CPTableColumn alloc] initWithIdentifier:headerKey];
		[[column headerView] setStringValue:headerKey];
		[column setWidth:140.0];
		[column setEditable:YES];
		[column setSortDescriptorPrototype:desc];
		[[column headerView] setBackgroundColor:headerColor];
		[tableView addTableColumn:column];
	}

    [scrollView setDocumentView:tableView]; 
	[tableView reloadData]; 
	[self createFilterBar];
}

- (void)createMenu
{
    [CPMenu setMenuBarVisible:YES];
	var theMenu = [[CPApplication sharedApplication] mainMenu];
	
	var showAllMenuItem = [[CPMenuItem alloc] initWithTitle:showAll action:@selector(openDetailsInNewWindow:) keyEquivalent:nil];
	[theMenu insertItem:showAllMenuItem atIndex: 0];
	
	var showSelMenuItem = [[CPMenuItem alloc] initWithTitle:showSel action:@selector(openDetailsInNewWindow:) keyEquivalent:nil];
	[theMenu insertItem:showSelMenuItem atIndex: 1]

	[theMenu removeItemAtIndex:[theMenu indexOfItemWithTitle: @"New" ]];
	[theMenu removeItemAtIndex:[theMenu indexOfItemWithTitle: @"Open"]];
	[theMenu removeItemAtIndex:[theMenu indexOfItemWithTitle: @"Save"]];
}

- (void)createGroupView
{
	groupScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 50, CGRectGetWidth([leftView bounds]), CGRectGetHeight([leftView bounds])-50)];
	[groupScrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
	[groupScrollView setAutohidesScrollers:YES];

	groupView = [[CPTableView alloc] initWithFrame:[groupScrollView bounds]];
	[groupView setIntercellSpacing:CGSizeMakeZero()];
    [groupView setHeaderView:nil];
    [groupView setCornerView:nil];
	[groupView setDelegate:self];
	[groupView setDataSource:groupDS];
	[groupView setAllowsEmptySelection:NO];
	[groupView setBackgroundColor:[CPColor colorWithHexString:@"EBF3F5"]];



    var column = [[CPTableColumn alloc] initWithIdentifier:groupColId];
    [column setWidth:220.0];
    [column setMinWidth:50.0];
    
    [groupView addTableColumn:column];
    [groupView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [groupView setRowHeight:26.0];
	
	[groupScrollView setDocumentView:groupView];
}
- (void)createListView
{

	
	//create view to hold scrollView and filterBar
	scrollParentView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0, CGRectGetWidth([horizontalSplitter bounds]), 300.0)];
    	// create a CPScrollView that will contain the CPTableView
    	scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0, CGRectGetWidth([horizontalSplitter bounds]), 300.0)];
    	[scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable]; 

	//wordDS = [[WordDataSource alloc] init];
	//wordController = [[WordsController alloc] init];


    	// create the CPTableView
    	tableView = [[CPTableView alloc] initWithFrame:[scrollView bounds]];
        [tableView setDataSource:wordsController];
	//[wordsController getWord:@""];
	[tableView setAllowsEmptySelection:NO];
    	[tableView setUsesAlternatingRowBackgroundColors:YES];
    	[[tableView cornerView] setBackgroundColor:headerColor];
	[tableView setAllowsMultipleSelection:YES];
	[tableView setDelegate:wordsController];
	[tableView setTarget:self];
    	[tableView setDoubleAction:@selector(openDetailInNewWindow:)];
}
/*- (void)createWebView
{
	webView = [[DetailsWebView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([horizontalSplitter bounds])-16, CGRectGetHeight([horizontalSplitter bounds])-300)];
	[webView setAutoresizingMask: CPViewWidthSizable | CPViewMinYMargin | CPViewMaxYMargin];
}*/
- (void)createSearchField
{
    searchField = [[CPSearchField alloc] initWithFrame:CGRectMake(0, 10, 200, 30)];
	[searchField setEditable:YES];
	[searchField setPlaceholderString:@"search and hit enter"];
	[searchField setBordered:YES];
	[searchField setBezeled:YES];
	[searchField setFont:[CPFont systemFontOfSize:12.0]];
	[searchField setTarget:wordDS];
	[searchField setAction:@selector(searchChanged:)];
	[searchField setSendsWholeSearchString:NO]; 
}
- (void)createFilterBar
{
	filterBar = [[FilterBar alloc] initWithFrame:CGRectMake(0, 0, 400, 32) colHeaders:[wordDS columnHeaders]];
    [filterBar setAutoresizingMask:CPViewWidthSizable];
    [filterBar setDelegate:wordDS];
}
- (void)splitPage:(CGRect)aBounds
{
	// create a view to split the page by left/right
	verticalSplitter = [[CPSplitView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(aBounds), CGRectGetHeight(aBounds))];
	[verticalSplitter setDelegate:self];
	[verticalSplitter setVertical:YES]; 
	[verticalSplitter setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable ];
	[verticalSplitter setIsPaneSplitter:YES]; //1px splitter line	

	//create left/right views
	leftView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 200, CGRectGetHeight([verticalSplitter bounds]))];
	[leftView setBackgroundColor:[CPColor colorWithHexString:@"CCDDDD"]];
	rightView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([verticalSplitter bounds]) - 200, CGRectGetHeight([verticalSplitter bounds]))];
	[rightView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable ];

	// create a view to split the right view into top/bottom
	horizontalSplitter = [[CPSplitView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([rightView bounds]), CGRectGetHeight([rightView bounds]))];
	[horizontalSplitter setDelegate:self];
	[horizontalSplitter setVertical:NO]; 
	[horizontalSplitter setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable ]; 
}
- (void)combineViews
{
	// add search bar/groups to leftview
    	[leftView addSubview:searchField];
	[leftView addSubview:groupScrollView];
	
	// add scrollView/webView to right side of page
	[scrollParentView addSubview:scrollView];
	[horizontalSplitter addSubview:scrollParentView];
	//[horizontalSplitter addSubview:webView];
	
	// add horizontal view into right view in order to split top/bottom
	[rightView addSubview:horizontalSplitter];
	
	// add the left/right view to the veritcalview
	[verticalSplitter addSubview:leftView];
	[verticalSplitter addSubview:rightView];
}
@end
