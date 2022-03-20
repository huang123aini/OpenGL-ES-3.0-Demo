//
//  Draw_To_FBOUITestsLaunchTests.m
//  Draw_To_FBOUITests
//
//  Created by 黄世平 on 2022/3/20.
//

#import <XCTest/XCTest.h>

@interface Draw_To_FBOUITestsLaunchTests : XCTestCase

@end

@implementation Draw_To_FBOUITestsLaunchTests

+ (BOOL)runsForEachTargetApplicationUIConfiguration {
    return YES;
}

- (void)setUp {
    self.continueAfterFailure = NO;
}

- (void)testLaunch {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    // Insert steps here to perform after app launch but before taking a screenshot,
    // such as logging into a test account or navigating somewhere in the app

    XCTAttachment *attachment = [XCTAttachment attachmentWithScreenshot:XCUIScreen.mainScreen.screenshot];
    attachment.name = @"Launch Screen";
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
}

@end
