//
//  EventDataSOurce.m
//  SF iOS
//
//  Created by Amit Jain on 7/29/17.
//  Copyright © 2017 Amit Jain. All rights reserved.
//

#import "EventDataSource.h"
#import "Event.h"
#import "NSError+Constructor.h"

@interface EventDataSource ()

@property (nonatomic) CKDatabase *database;
@property (nonatomic) CKQueryCursor *cursor;

@end


@implementation EventDataSource

- (instancetype)initWithDatabase:(CKDatabase *)database {
    if (self = [super init]) {
        self.database = database;
    }
    
    return self;
}

- (void)fetchPreviousEventsOfType:(EventType)eventType withCompletionHander:(EventsFetchCompletionHandler)completionHandler {
    __weak typeof(self) welf = self;
    __block NSArray<CKRecord *> *eventRecords;
    
    CKFetchRecordsOperation *locationsOperation = [self locationRecordsFetchOperationWithCompletionHandler:^(NSDictionary<CKRecordID *,CKRecord *> * _Nullable recordsByRecordID, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil, error);
            });
            return;
        }
        
        NSArray<Event *> *events = [welf eventsFromEventRecords:eventRecords locationRecordsByID:recordsByRecordID];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(events, nil);
        });
    }];
    
    CKQueryOperation *eventRecordsOperation = [self eventRecordsQueryOperationForEventsOfType:eventType withCursor:self.cursor completionHandler:^(CKQueryCursor *cursor, NSArray<CKRecord *> *records, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil, error);
            });
            return;
        }
        welf.cursor = cursor;
        eventRecords = records;
        
        locationsOperation.recordIDs = [welf locationRecordIDsFromEventRecords:eventRecords];
        [self.database addOperation:locationsOperation];
    }];
    
    [self.database addOperation:eventRecordsOperation];
}

// MARK: - CloudKit Operations Construction

- (CKQueryOperation *)eventRecordsQueryOperationForEventsOfType:(EventType)eventType withCursor:(CKQueryCursor *)cursor completionHandler: (void (^)(CKQueryCursor *cursor, NSArray<CKRecord *> *records, NSError *error))completionHandler {
    NSString *recordType = Event.recordName;
    
    CKQueryOperation *operation = nil;
    if (cursor) {
        operation = [[CKQueryOperation alloc] initWithCursor:cursor];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"eventType == %u", eventType];
        CKQuery *query = [[CKQuery alloc] initWithRecordType:recordType predicate:predicate];
        query.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"eventDate" ascending:false]];
        operation = [[CKQueryOperation alloc] initWithQuery:query];
    }
    
    __block NSMutableArray<CKRecord *> *records = [NSMutableArray new];
    operation.recordFetchedBlock = ^(CKRecord * _Nonnull record) {
        if (![record.recordType isEqualToString:recordType]) {
            NSAssert(false, @"Received a record of unexpected type: %@", record.recordType);
            return;
        }
        [records addObject:record];
    };
    operation.queryCompletionBlock = ^(CKQueryCursor * _Nullable cursor, NSError * _Nullable operationError) {
        if (operationError != nil) {
            completionHandler(nil, nil, operationError);
            return;
        }
        
        completionHandler(cursor, records, nil);
    };
    operation.resultsLimit = 10;
    
    return operation;
}

- (CKFetchRecordsOperation *)locationRecordsFetchOperationWithCompletionHandler:(void (^)(NSDictionary<CKRecordID *,CKRecord *> * _Nullable recordsByRecordID, NSError * _Nullable error))completionHandler {
    NSMutableArray<CKRecord *> *locationRecords = [NSMutableArray new];
    CKFetchRecordsOperation *operation = [CKFetchRecordsOperation new];
    operation.perRecordCompletionBlock = ^(CKRecord * _Nullable record, CKRecordID * _Nullable recordID, NSError * _Nullable error) {
        if (record == nil) {
            NSError *fallbackError = [NSError appErrorWithDescription:@"Record of type %@ with id %@ could not be found."];
            completionHandler(nil, error ? error : fallbackError);
            return;
        }
        
        [locationRecords addObject:record];
    };
    
    operation.fetchRecordsCompletionBlock = completionHandler;
    
    return operation;
}

// MARK: - Records Parsing

- (NSArray<Event *> *)eventsFromEventRecords:(NSArray<CKRecord *> *)eventRecords locationRecordsByID:(NSDictionary<CKRecordID *,CKRecord *> *) locationRecordsByRecordID {
    NSAssert(eventRecords.count == locationRecordsByRecordID.count,
             @"Number of events %lu != Number of locations %lu", (unsigned long)eventRecords.count, locationRecordsByRecordID.count);
    
    NSMutableArray<Event *> *events = [NSMutableArray new];
    for (CKRecord *eventRecord in eventRecords) {
        CKRecordID *locationRecordID = [self locationRecordIDFromEventRecord:eventRecord];
        if (!locationRecordID) {
            NSAssert(false, @"Location corresponding to Event does not exist\n%@", eventRecord);
            break;
        }
        Location *location = [[Location alloc] initWithRecord:locationRecordsByRecordID[locationRecordID]];
        Event *event = [[Event alloc] initWithRecord:eventRecord location:location];
        [events addObject:event];
    }
    
    return events;
}
                                          
- (CKRecordID *)locationRecordIDFromEventRecord:(CKRecord *)eventRecord {
    CKReference *locationReference = [eventRecord objectForKey:@"location"];
    return locationReference.recordID;
}

- (NSArray<CKRecordID *> *)locationRecordIDsFromEventRecords:(NSArray<CKRecord *> *)eventRecords {
    NSMutableArray<CKRecordID *> *recordIDs = [NSMutableArray new];
    for (CKRecord *eventRecord in eventRecords) {
        [recordIDs addObject:[self locationRecordIDFromEventRecord:eventRecord]];
    }
    return recordIDs;
}

@end