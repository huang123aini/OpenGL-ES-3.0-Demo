//
//  BlinnPhong_Light_ModelUITestsLaunchTests.m
//  BlinnPhong_Light_ModelUITests
//
//  Created by 黄世平 on 2022/4/20.
//

#import <XCTest/XCTest.h>

@interface BlinnPhong_Light_ModelUITestsLaunchTests : XCTestCase

@end

@implementation BlinnPhong_Light_ModelUITestsLaunchTests

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
