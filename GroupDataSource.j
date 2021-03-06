@implementation GroupDataSource : CPObject
{
	JSObject objs @accessors;
}
- (id)init
{
	if(self = [super init])
	{
		//objs = [@"test", @"test2"];
        objs = [];
		[self getGroups];

        console.log(objs);
	}
	return self;
}
- (void)getGroups
{
	var request = [CPURLRequest requestWithURL:requestGroupURL];
//	console.log(requestGroupURL);
    [[CPURLConnection alloc] initWithRequest:request delegate:self];
}
- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)data
{
	objs = CPJSObjectCreateWithJSON(data);
	
	[[CPNotificationCenter defaultCenter]
		postNotificationName:reloadGroupsNoti object:nil];
}
- (void)connection:(CPURLConnection)aConnection didFailWithError:(CPString)error
{
    alert(error) ;
}
- (int)numberOfRowsInTableView:(CPTableView)tableView
{
	return [objs count];
}
- (id)tableView:(CPTableView)tableView objectValueForTableColumn:(CPTableColumn)tableColumn row:(int)row
{
	return objs[row];
}
@end
