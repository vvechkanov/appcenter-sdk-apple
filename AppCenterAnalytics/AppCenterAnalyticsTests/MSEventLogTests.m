#import "MSAbstractLogInternal.h"
#import "MSAbstractLogPrivate.h"
#import "MSAppExtension.h"
#import "MSCSData.h"
#import "MSCSExtensions.h"
#import "MSCSModelConstants.h"
#import "MSDeviceInternal.h"
#import "MSEventLogPrivate.h"
#import "MSEventPropertiesInternal.h"
#import "MSLocExtension.h"
#import "MSLogWithProperties.h"
#import "MSNetExtension.h"
#import "MSOSExtension.h"
#import "MSProtocolExtension.h"
#import "MSSDKExtension.h"
#import "MSStringTypedProperty.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Date.h"

@interface MSEventLogTests : XCTestCase

@property(nonatomic) MSEventLog *sut;

@end

@implementation MSEventLogTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [MSEventLog new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingEventToDictionaryWorks {

  // If
  NSString *typeName = @"event";
  NSString *eventId = MS_UUID_STRING;
  NSString *eventName = @"eventName";
  MSDevice *device = [MSDevice new];
  NSString *sessionId = @"1234567890";
  NSDictionary *properties = @{ @"Key" : @"Value" };
  NSDate *timestamp = [NSDate date];

  self.sut.eventId = eventId;
  self.sut.name = eventName;
  self.sut.device = device;
  self.sut.timestamp = timestamp;
  self.sut.sid = sessionId;
  self.sut.properties = properties;

  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"id"], equalTo(eventId));
  assertThat(actual[@"name"], equalTo(eventName));
  assertThat(actual[@"device"], notNilValue());
  assertThat(actual[@"sid"], equalTo(sessionId));
  assertThat(actual[@"type"], equalTo(typeName));
  assertThat(actual[@"properties"], equalTo(properties));
  assertThat(actual[@"device"], notNilValue());
  assertThat(actual[@"timestamp"], equalTo([MSUtility dateToISO8601:timestamp]));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  NSString *typeName = @"event";
  NSString *eventId = MS_UUID_STRING;
  NSString *eventName = @"eventName";
  MSDevice *device = [MSDevice new];
  NSString *sessionId = @"1234567890";
  NSDate *timestamp = [NSDate date];
  NSDictionary *properties = @{ @"Key" : @"Value" };

  self.sut.eventId = eventId;
  self.sut.name = eventName;
  self.sut.device = device;
  self.sut.timestamp = timestamp;
  self.sut.sid = sessionId;
  self.sut.properties = properties;

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSEventLog class]));
  MSEventLog *actualEvent = actual;
  assertThat(actualEvent.name, equalTo(eventName));
  assertThat(actualEvent.eventId, equalTo(eventId));
  assertThat(actualEvent.device, notNilValue());
  assertThat(actualEvent.timestamp, equalTo(timestamp));
  assertThat(actualEvent.type, equalTo(typeName));
  assertThat(actualEvent.sid, equalTo(sessionId));
  assertThat(actualEvent.properties, equalTo(properties));
  XCTAssertTrue([self.sut isEqual:actualEvent]);
}

- (void)testIsValid {

  // If
  self.sut.device = OCMClassMock([MSDevice class]);
  OCMStub([self.sut.device isValid]).andReturn(YES);
  self.sut.timestamp = [NSDate date];
  self.sut.sid = @"1234567890";

  // Then
  XCTAssertFalse([self.sut isValid]);

  // When
  self.sut.eventId = MS_UUID_STRING;

  // Then
  XCTAssertFalse([self.sut isValid]);

  // When
  self.sut.name = @"eventName";

  // Then
  XCTAssertTrue([self.sut isValid]);
}

- (void)testIsNotEqualToNil {

  // Then
  XCTAssertFalse([self.sut isEqual:nil]);
}

- (void)testConvertACPropertiesToCSPropertiesWhenACPropertiesNil {

  // When
  NSDictionary *csProperties = [self.sut convertTypedPropertiesToCSProperties];

  // Then
  XCTAssertNil(csProperties);
}

- (void)testConvertACPropertiesToCSPropertiesWhenPropertiesAreNotNested {

  // If
  MSEventProperties *acProperties = [MSEventProperties new];
  [acProperties setString:@"value" forKey:@"key"];
  [acProperties setString:@"value2" forKey:@"key2"];
  self.sut.typedProperties = acProperties;

  // When
  NSDictionary *csProperties = [self.sut convertTypedPropertiesToCSProperties];

  // Then
  XCTAssertEqual([csProperties count], [acProperties.properties count]);
  for (NSString *key in acProperties.properties.allKeys) {
    XCTAssertEqual(csProperties[key], ((MSStringTypedProperty *)acProperties.properties[key]).value);
  }
}

- (void)testConvertACPropertiesToCSPropertiesWhenPropertiesAreNested {

  // If
  MSEventProperties *acProperties = [MSEventProperties new];
  [acProperties setString:@"buriedValue" forKey:@"nes.t.ed"];
  self.sut.typedProperties = acProperties;

  // When
  NSDictionary *csProperties = [self.sut convertTypedPropertiesToCSProperties];

  // Then
  XCTAssertEqualObjects(csProperties, @{@"nes": @{@"t": @{@"ed": @"buriedValue"}}});
}

- (void)testConvertACPropertiesToCSPropertiesWhenPropertiesAreNestedWithSiblings {
  // If
  MSEventProperties *acProperties = [MSEventProperties new];
  [acProperties setString:@"value" forKey:@"key"];
  [acProperties setString:@"1" forKey:@"nes.a"];
  [acProperties setString:@"2" forKey:@"nes.t.ed"];
  [acProperties setString:@"3" forKey:@"nes.t.ed2"];
  [acProperties setString:@"value2" forKey:@"key2"];
  self.sut.typedProperties = acProperties;
  NSDictionary *expectedResult = @{ @"key" : @"value", @"nes" : @{@"a" : @"1", @"t" : @{@"ed" : @"2", @"ed2" : @"3"}}, @"key2" : @"value2" };

  // When
  NSDictionary *csProperties = [self.sut convertTypedPropertiesToCSProperties];

  // Then
  XCTAssertEqualObjects(csProperties, expectedResult);
}

- (void)testOverrideValueToObjectProperties {

  // If
  MSEventProperties *acProperties = [MSEventProperties new];
  [acProperties setString:@"1" forKey: @"a.b"];
  [acProperties setString:@"2" forKey:@"a.b.c.d" ];
  self.sut.typedProperties = acProperties;
  NSDictionary *possibleResult1 = @{ @"a" : @{@"b" : @"1"} };
  NSDictionary *possibleResult2 = @{ @"a" : @{@"b" : @{@"c" : @{@"d" : @"2"}}} };

  // When
  NSDictionary *csProperties = [self.sut convertTypedPropertiesToCSProperties];

  // Then
  XCTAssertEqual([csProperties count], 1);
  XCTAssertTrue([csProperties isEqualToDictionary:possibleResult1] || [csProperties isEqualToDictionary:possibleResult2]);
}

- (void)testOverrideObjectToValueProperties {

  // If
  MSEventProperties *acProperties = [MSEventProperties new];
  [acProperties setString:@"1" forKey:@"a.b.c.d"];
  [acProperties setString:@"2" forKey:@"a.b"];
  self.sut.typedProperties = acProperties;

  // When
  NSDictionary *csProperties = [self.sut convertTypedPropertiesToCSProperties];
  NSDictionary *test1 = @{ @"a" : @{@"b" : @{@"c" : @{@"d" : @"1"}}} };
  NSDictionary *test2 = @{ @"a" : @{@"b" : @"2"} };

  // Then
  XCTAssertEqual([csProperties count], 1);
  XCTAssertTrue([csProperties isEqualToDictionary:test1] || [csProperties isEqualToDictionary:test2]);
}

- (void)testOverrideValueToValueProperties {

  // If
  MSEventProperties *acProperties = [MSEventProperties new];
  [acProperties setString:@"1" forKey:@"a.b"];
  [acProperties setString:@"2" forKey:@"a.b"];
  self.sut.typedProperties = acProperties;

  // When
  NSDictionary *csProperties = [self.sut convertTypedPropertiesToCSProperties];
  NSDictionary *test1 = @{ @"a" : @{@"b" : @"1"} };
  NSDictionary *test2 = @{ @"a" : @{@"b" : @"2"} };

  // Then
  XCTAssertEqual([csProperties count], 1);
  XCTAssertTrue([csProperties isEqualToDictionary:test1] || [csProperties isEqualToDictionary:test2]);
}

- (void)testToCommonSchemaLogForTargetToken {

  // If
  NSString *targetToken = @"aTarget-Token";
  NSString *name = @"SolarEclipse";
  NSDictionary *properties = @{ @"StartedAt" : @"11:00", @"VisibleFrom" : @"Redmond" };
  NSDate *timestamp = [NSDate date];
  MSDevice *device = [MSDevice new];
  NSString *oemName = @"Peach";
  NSString *model = @"pPhone1,6";
  NSString *locale = @"en_US";
  NSString *osName = @"pOS";
  NSString *osVer = @"1.2.4";
  NSString *osBuild = @"2342EEWF";
  NSString *appNamespace = @"com.contoso.peach.app";
  NSString *appVersion = @"3.1.2";
  NSString *carrierName = @"P-Telecom";
  NSString *sdkVersion = @"1.0.0";
  device.oemName = oemName;
  device.model = model;
  device.locale = locale;
  device.osName = osName;
  device.osVersion = osVer;
  device.osBuild = osBuild;
  device.appNamespace = appNamespace;
  device.appVersion = appVersion;
  device.carrierName = carrierName;
  device.sdkName = @"appcenter.ios";
  device.sdkVersion = sdkVersion;
  device.timeZoneOffset = @(-420);
  self.sut.device = device;
  self.sut.timestamp = timestamp;
  self.sut.name = name;
  self.sut.properties = properties;

  // When
  MSCommonSchemaLog *csLog = [self.sut toCommonSchemaLogForTargetToken:targetToken];

  // Then
  XCTAssertEqualObjects(csLog.ver, kMSCSVerValue);
  XCTAssertEqualObjects(csLog.name, name);
  XCTAssertEqualObjects(csLog.timestamp, timestamp);
  XCTAssertEqualObjects(csLog.iKey, @"o:aTarget");
  XCTAssertEqualObjects(csLog.ext.protocolExt.devMake, oemName);
  XCTAssertEqualObjects(csLog.ext.protocolExt.devModel, model);
  XCTAssertEqualObjects(csLog.ext.appExt.locale, [[[NSBundle mainBundle] preferredLocalizations] firstObject]);
  XCTAssertEqualObjects(csLog.ext.osExt.name, osName);
  XCTAssertEqualObjects(csLog.ext.osExt.ver, @"Version 1.2.4 (Build 2342EEWF)");
  XCTAssertEqualObjects(csLog.ext.appExt.appId, @"I:com.contoso.peach.app");
  XCTAssertEqualObjects(csLog.ext.appExt.ver, device.appVersion);
  XCTAssertEqualObjects(csLog.ext.netExt.provider, carrierName);
  XCTAssertEqualObjects(csLog.ext.sdkExt.libVer, @"appcenter.ios-1.0.0");
  XCTAssertEqualObjects(csLog.ext.locExt.tz, @"-07:00");
  XCTAssertEqualObjects(csLog.data.properties, properties);
}

@end
