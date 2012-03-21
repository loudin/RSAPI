REST Simple API  v0.9.0
=================

REST Simple API, or RSAPI is an iOS library that streamlines the work required to integrate a RESTful web service with an iPhone Core Data store. After setting up your data models, making a call to your server is as easy as:

    RSAPI *api = [RSAPI sharedAPI];
    [api call:@"/path/to/your/web/service" params:[NSDictionary dictionaryWithObjectsAndKeys:firstParamDict,@"firstParamName",nil] withDelegate:self];

RSAPI will call one of two delegate methods:

    -(void)apiDidReturn:(id)arrOrDict forRoute:(NSString*)action{
        //Execute code on successful completion.
        //arrOrDict is your JSON data
        //action is the path called
    }
    -(void)apiDidFail:(NSError*)error forRoute:(NSString*)action{
        //On failure, this is called.
        //action is the path called
    }

Requirements
===========

RSAPI depends on AFNetworking. AFNetworking is a well-documented and powerful iOS/Mac OSX library that carries out HTTP requests and JSON data conversion. If you haven't been using it, you
should. 

I am going to include the latest build of AFNetworking that is compatible with RSAPI. For future releases, I want to remove the dependency by abstrcting the functionality out to support other popular networking frameworks.

AFNetworking itself uses NSJSONSerialization if it is available. If not, you must use either JSONKit, SBJson, or YAJL to parse JSON requests. AFNetworking will automatically detect the correct library.

RSAPI supports iOS4.0 and above. In order to use Object Mapping, your project must have a Core Data store. All data sent back from your server must be encoded as JSON.

The Guide to Setting Up and Using RSAPI
=================================

**I recently presented RSAPI at the New York iOS Developers Meetup. I have included the slides in the repository, as they provide a detailed overview about how to use the library**

RSAPI consists of three classes that do the work for you:

- RSModelHelper: Scaffolding code for you to specify how your JSON models match up to your Core Data models.
- RSAPI: Responsible for making API calls, helpers for encoding GET/POST parameters, Core Data maintenance.
- RSDataFetcher: Abstraction of NSFechedResultsController. Supports live updates of UITableViews that display Core Data models.

Setting Up RSModelHelper
-------------------------------------

This is the most important step of the setup process, so please be sure to understand what is going on here.

### Linking Core Data properties with JSON properties
When you create a web service for your app, you will need to send data about your server-side objects to your iPhone app. Sometimes, for a given object, the JSON properties align up exactly with the Core Data properties. However, there are times when this is not the case. In these instances, you need to program RSModelHelper to know when to make these exceptions and how to match irregular JSON properties with your Core Data properties.

For example, let's say you have a User object. Here are the representations:

<table>
    <tr>
       <td>
       Server (JSON)
			 </td>
			 <td>
			 Core Data
			 </td>
		</tr>
		<tr>
			<td>
				<ul>
					<li>user_id</li>
       		<li>name</li>
       		<li>email</li>
       		<li>avatar_sm</li>
       		<li>friends</li>
				</ul>
      </td>
      <td>
      	<ul>
					<li>userID</li>
					<li>name</li>
					<li>email</li>
					<li>avatarSm</li>
       		<li>friends</li>
			  </ul>
       </td>
    </tr>
</table>

The JSON properties name, email, and friends match up with the Core Data properties. However, the JSON properties of user_id and avatar_sm do not match up with the corresponding Core Data properties. To handle this, look towards the RSModelHelper method <code>jsonPropertyMapForClass:(NSString*)className</code>.

The function <code>jsonPropertyMapForClass:(NSString*)className</code> passes a Core Data class name converted to a string. Based on that class name, you must return an NSDictionary whose objects are the JSON properties and whose keys are the matching Core Data properties. You need only return the properties that do not match up, so in the example above, you could write:

    - (void)jsonPropertyMapForClass:(NSString*)className{
        if ([className isEqualToString:@"User"]){
            return [NSDictionary dictionaryWithObjectsAndKeys:
              @"user_id",@"userID",
              @"avatar_sm",@"avatarSm",
              nil];
        }
    }

You must remember to do this for each of your Core Data models. If all of your Core Data models match up with your JSON appropriately, simply return nil.

###Specifying the ID for your model

RSAPI needs to know the ID for your model so that it can query your Core Data store to determine if it should overwrite an existing object or insert a new object. The function <code>jsonIdKeyForClass:(NSString*)className</code> passes the Core Data class name as a string and you must return its JSON ID property. For example:

    - (NSString*)jsonIdKeyForClass:(NSString*)className{
        if ([className isEqualToString:@"User"]){
            return @"user_id";
        }
        return @"id";
    }

For the User model above, we return @"user_id" because that is the JSON ID property. However, for all of our other models, we default to the JSON property of @"id". So, if you have another model called Order, the JSON that is returned from the server would have an ID property of "id". It is strongly recommended that your JSON models have ID properties of @"id".

Initializing RSAPI
------------------------

Next, open up your App Delegate and as soon as you can, write in the following initialization code:

      RSAPI *api = [RSAPI 
                    setupWithManagedObjContext:self.managedObjectContext        //Pass your app delegate's managedObjectContext
                    withPersistentStoreCoord:self.persistentStoreCoordinator           //Pass your app delegate's persistintStoreCoordinator
                    withManagedObjModel:self.managedObjectModel                        //Pass your app delegate's managedObjectModel
                    withDevelopmentBase:@"http://localhost:3000"                              //Pass your development baseURL
                    withProductionBase:@"http://www.boundaboutwith.us"                 //Pass your production baseURL
                    ];

Most of this is boilerplate with the exception of the development base and the production base. For these variables, include the base URL of your development and production environments accordingly.

It is important to note that RSAPI automatically assumes you are using your production base. To change this, call <code>[RSAPI setProduction:NO];</code>.

Setting Up Your Paths
------------------------------

Right after your initialization method in your app delegate, you need to set up your routes. This is very easy to do:

    [api setPath:@"/path/to/object" forClass:@"CoreDataObjectClass" requestType:RSHTTPRequestTypeGet];   //Set up get request for an object
    [api setPath:@"/path/to/object" forClass:@"CoreDataObjectClass" requestType:RSHTTPRequestTypePost];  //Set up post request for an object
    
RSAPI supports variables within paths, so it is perfectly legal to create the path:

    [api setPath:@"/api/users/:id" forClass:@"User" requestType:RSHTTPRequestTypeGet];
    [api setPath:@"/api/groups/:id/users/" forClass:@"Group" requestType:RSHTTPRequestTypeGet];
    [api setPath:@"/api/groups/:gid/messages/:mid" forClass:@"Message" requestType:RSHTTPRequestTypePost];
    
I will cover how to set up these requests later on.

### Returning Plain JSON Data / Bypassing Core Data Synchronization

There are times when you want to return plain JSON data or bypass Core Data synchronization. For these cases, just pass @"DATA" as the route's class:

    [api setPath:@"/path/to/data/request" forClass:@"DATA" requestType:RSHTTPRequestTypePost];
    
This will force RSAPI to immediately return your JSON data to the <code>apiDidReturn:</code> method without Core Data processing.

### Returning multiple JSON objects

Although this is not a true RESTful implementation, there might be times when you want to return multiple objects for a given path. Such an instance would be when you need to perform an initialization method when someone first launches your app. For these instances, simply return @"MANY" for the class name:

    [api setPath:@"/path/to/many/objects" forClass:@"MANY" requestType:RSHTTPRequestTypeGet];

When you do this, your JSON MUST be structured in the following way:

    [{
        "CoreDataClassName": [{
            "obj_prop_1": "obj_value_1",
            "obj_prop_2": "obj_value_2",
            ...etc
        }],
        "CoreDataClassName": [{
            "obj_prop_1": "obj_value_1",
            "obj_prop_2": "obj_value_2",
            ...etc
        }]
    }]
    
Working with RSDataFetcher
---------------------------------------

RSDataFetcher is designed to be a Core Data abstraction for returning data based on your view. I plan on enhancing the functionality to include matching fetch requests up with routes, but for now, it's an extremely handy wrapper class for NSFetchedResultsController.

NSFetchedResultsController is a fairly reliable class designed by Apple to populate UITableViews with data from a NSFetchRequest. NSFetchedResultsController has a Delegate class that even automatically updates the UITableView if the Core Data store changes. This is a pretty powerful class, but the major drawbacks are that you need to implement the delegate in every class that uses it and there are weird bugs when you incrementally update your Core Data store or employ threading.

RSDataFetcher fixes most of these issues. If you have a UITableView and you wish to use RSDataFetcher to automatically populate and update your UITableView with data, here's how you do it:

    RSDataFetcher *dataFetcher = [[RSDataFetcher alloc] 
                        initWithFetchRequest:fetchRequest      //The fetch request that you wish to populate the table with
                        inContext:context                // The managed object context that contains your data
                        withKeyPath:keyPath           // If your UITableView is partitioned into sections, pass the key of the Core Data model you're fetching responsible for the section titles
                        usingCache:cache              // If you wish to cache your core data requests, pass a string for your cacheName here.
                        inTableView:tableView           // The tableView that is going to be refreshed.
                        ];

One drawback of NSFetchedResultsController is that your entire table view must be dedicated to the display of the data. With RSDataFetcher you can set an offset that allows the first n sections of the UITableView to remain unpopulted.

    [dataFetcher setSectionOffset:n];   //Where n is the first n sections of the UITableView that will not display your returned data
    
Finally, to initiate the fetch of data, call:

    [dataFetcher performFetch];
    
### A couple of notes

RSDataFetcher contains a delegate method that lets you know when its finished updating your UITableView. Simple implement <code>-(void)folioDataFetcherDidFinishUpdating:(RSDataFetcher*)dataFetcher;</code> and set the RSDataFetcher delegate to use it.

You MUST call <code>[yourDataFetcher performUpdate]</code> in order to initiate an update on your UITableView. You can place this method in the <code>apiDidReturn:forRoute:</code> RSAPIDelegate method. You can also call: <code>[RSAPI call:params:withDelegate:withDataFetcher:]</code> when you make your API request. Simply pass your RSDataFetcher in that method and your view will automatically update after your request completes. No need to repeat yourself in the <code>apiDidReturn:forRoute:</code> delegate method.

There are times when you wish to dynamically alter your NSFetchRequest for a given UITableView. In order to do this, simply call the method:

    [yourDataFetcher refreshRequestWithPredicate:newPredicate andSortDescriptors:newSortDescriptors];
  
If you want to completely refresh your NSFetchRequest, just release and allocate a new instance of it.

Improvements for Future Releases
===========================

I developed RSAPI to be a great out-of-the-box solution to linking your iPhone Data Model to your RESTful web service. In terms of future improvements, I want to keep the library nimble and well-documented. Here are some a list of improvements I would like to make before the v1.0 release:

- Multithreaded Core Data synchronization
-- Currently, the synchronization process between the iPhone app and server has a runtime of O(n), but is thread-blocking. Introducing threading will free up the UI while requests come in. This is only a problem when your n is high, but a worthy problem to tackle nevertheless.
- Remove AFNetworking dependency
-- I don't like it when frameworks ship with dependencies, so I want to abstract the network requests the library makes so people can use a couple of different popular frameworks
- ARC Support
-- I started this library before iOS5, which has ARC Support. Offering two libraries: one with and one without ARC is essential.

Credits
======

RSAPI was created by Michael Dinerstein to streamline development of [Boundabout](http://www.boundaboutwith.us/).

The inspiration for this library came from [RESTKit](http://restkit.org/).

You can contact Michael at:

- [michael@boundaboutwith.us](mailto:michael@boundaboutwith.us)

License
======
RSAPI is available under the MIT license. 

