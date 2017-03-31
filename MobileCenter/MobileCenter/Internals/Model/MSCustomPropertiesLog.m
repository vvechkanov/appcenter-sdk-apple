#import "MSCustomPropertiesLog.h"

static NSString *const kMSCustomProperties = @"custom_properties";
static NSString *const kMSProperties = @"properties";
static NSString *const kMSPropertyType = @"type";
static NSString *const kMSPropertyName = @"name";
static NSString *const kMSPropertyValue = @"value";
static NSString *const kMSPropertyTypeClear = @"clear";
static NSString *const kMSPropertyTypeBoolean = @"boolean";
static NSString *const kMSPropertyTypeNumber = @"number";
static NSString *const kMSPropertyTypeDateTime = @"date_time";
static NSString *const kMSPropertyTypeString = @"string";

@implementation MSCustomPropertiesLog

@synthesize type = _type;
@synthesize properties = _properties;

- (instancetype)init {
  self = [super init];
  if( self ) {
    self.type = kMSCustomProperties;
  }
  return self;
}

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  
  if (self.properties) {
    NSMutableArray *propertiesArray = [NSMutableArray array];
    for (NSString *key in self.properties) {
      NSObject *value = [self.properties objectForKey:key];
      NSMutableDictionary *property = [MSCustomPropertiesLog serializeProperty: value];
      [property setObject:key forKey:kMSPropertyName];
    }
    dict[kMSProperties] = propertiesArray;
  }  return dict;
}

+ (NSMutableDictionary *)serializeProperty:(NSObject *)value {
  static NSDateFormatter *dateFormatter = nil;
  if (!dateFormatter) {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale systemLocale]];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation: @"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
  }
  NSMutableDictionary *property = [NSMutableDictionary new];
  if ([value isKindOfClass:[NSNull class]]) {
    [property setObject:kMSPropertyTypeClear forKey:kMSPropertyType];
  } else if ([value isKindOfClass:[NSNumber class]]) {
    NSNumber * numberValue = (NSNumber *)value;
    if (!strcmp([numberValue objCType], @encode(BOOL))) {
      [property setObject:kMSPropertyTypeBoolean forKey:kMSPropertyType];
      [property setObject:value forKey:kMSPropertyValue];
    } else {
      [property setObject:kMSPropertyTypeNumber forKey:kMSPropertyType];
      [property setObject:value forKey:kMSPropertyValue];
    }
  } else if ([value isKindOfClass:[NSDate class]]) {
    [property setObject:kMSPropertyTypeDateTime forKey:kMSPropertyType];
    [property setObject:[dateFormatter stringFromDate:(NSDate *)value] forKey:kMSPropertyValue];
  } else if ([value isKindOfClass:[NSString class]]) {
    [property setObject:kMSPropertyTypeString forKey:kMSPropertyType];
    [property setObject:value forKey:kMSPropertyValue];
  }
  return property;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _properties = [coder decodeObjectForKey:kMSProperties];
  }
  
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.properties forKey:kMSProperties];
}

@end
