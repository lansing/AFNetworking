//
//  AFHTTPSessionManagerTests.m
//  AFNetworking Tests
//
//  Created by Max Lansing on 3/19/14.
//  Copyright (c) 2014 AFNetworking. All rights reserved.
//

#import "AFTestCase.h"

#import "AFHTTPSessionManager.h"

@interface AFHTTPSessionManagerTests : AFTestCase
@end

@implementation AFHTTPSessionManagerTests

- (void)testUploadStreaming
{
    [self writeTestFile];
    
    AFHTTPSessionManager *sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:self.baseURL];
    
    NSURL *requestUrl = [NSURL URLWithString:@"/post" relativeToURL:self.baseURL];

    NSError *errorFormAppend;
    NSError *errorRequest;
    __block NSError *errorTask;

    NSMutableURLRequest *request = [sessionManager.requestSerializer
        multipartFormRequestWithMethod:@"POST"
                             URLString:requestUrl.absoluteString
                            parameters:nil
             constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
               NSError *error = errorFormAppend;
                 [formData appendPartWithFileURL:[self testFileURL]
                                            name:@"test.txt"
                                           error:&error];
             }
                                 error:&errorRequest];
  
    NSProgress *progress;
    
    __block BOOL completeBlockCalled = NO;
    __block BOOL progressBlockCalled = NO;
  
    NSURLSessionUploadTask *task = [sessionManager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        errorTask = error;
        completeBlockCalled = YES;
    }];
    
    [task resume];
    
    [progress addObserver:self
               forKeyPath:@"fractionCompleted"
                  options:NSKeyValueObservingOptionNew
                  context:&progressBlockCalled];
  
    expect(errorFormAppend).will.beNil();
    expect(errorRequest).will.beNil();
    expect(errorTask).will.beNil();
    expect(task.state).will.equal(NSURLSessionTaskStateCompleted);
    expect(progress.totalUnitCount).beGreaterThan(0);
    expect(task.countOfBytesExpectedToSend).will.equal(NSURLSessionTransferSizeUnknown);
    expect(progress.fractionCompleted).will.equal(1.0);
    expect(completeBlockCalled).will.beTruthy();
    expect(progressBlockCalled).will.beTruthy();
}

- (void)testPostMultipart
{
    [self writeTestFile];
    
    AFHTTPSessionManager *sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:self.baseURL];
  
    NSURL *requestUrl = [NSURL URLWithString:@"/post" relativeToURL:self.baseURL];
  
    __block BOOL completeBlockCalled = NO;
    NSError *errorFormAppend;
    __block NSError *errorPost;
  
    NSURLSessionDataTask *task = [sessionManager POST:requestUrl.absoluteString
                                           parameters:nil
                            constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSError *error = errorFormAppend;
        [formData appendPartWithFileURL:[self testFileURL]
                                   name:@"test.txt"
                                  error:&error];
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        completeBlockCalled = YES;
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        errorPost = error;
    }];
  
    expect(errorFormAppend).will.beNil();
    expect(errorPost).will.beNil();
    expect(task.state).will.equal(NSURLSessionTaskStateCompleted);
    expect(completeBlockCalled).will.beTruthy();
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"fractionCompleted"]) {
        BOOL *progressBlockCalled = context;
        *progressBlockCalled = YES;
    }
}

- (NSURL *)testFileURL {
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    return [[tmpDirURL URLByAppendingPathComponent:@"test"] URLByAppendingPathExtension:@"txt"];
}

- (void)writeTestFile {
    NSError *error;
    NSString *testString = @"Testing, 1, 2, 3, 4, 5.";
    [testString writeToURL:[self testFileURL] atomically:YES encoding:NSStringEncodingConversionAllowLossy error:&error];
}


@end
