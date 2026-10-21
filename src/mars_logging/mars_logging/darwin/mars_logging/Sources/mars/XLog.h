#import <Foundation/Foundation.h>
#import <mars/xlog/xloggerbase.h>

typedef NS_ENUM(NSUInteger, XLogLevel) {
    XLogLevelAll = kLevelAll,
    XLogLevelVerbose = kLevelVerbose,
    XLogLevelDebug = kLevelDebug,
    XLogLevelInfo = kLevelInfo,
    XLogLevelWarning = kLevelWarn,
    XLogLevelError = kLevelError,
    XLogLevelFatal = kLevelFatal,
    XLogLevelNone = kLevelNone,
};

typedef NS_ENUM(NSUInteger, AppenderMode) {
    AppenderModeAsync,
    AppenderModeSync,
};

typedef NS_ENUM(NSUInteger, CompressMode) {
    CompressModeZlib,
    CompressModeZstd,
};

typedef NS_ENUM(NSUInteger, CompressLevel) {
    CompressLevel1,
    CompressLevel2,
    CompressLevel3,
    CompressLevel4,
    CompressLevel5,
    CompressLevel6,
    CompressLevel7,
    CompressLevel8,
    CompressLevel9,
};

@interface XLog: NSObject

+ (void)open: (AppenderMode)mode level: (XLogLevel)level logsDir: (NSString*)logsDir cacheDir: (NSString*)cacheDir cacheDays: (int)cacheDays namePrefix: (NSString*)namePrefix compressMode: (CompressMode)compressMode compressLevel: (CompressLevel)compressLevel pubKey: (NSString*)pubKey useConsole: (bool)useConsole maxFileSize: (uint64_t)maxFileSize maxAliveDuration: (long)maxAliveDuration;
+ (void)flush: (bool)isSync;
+ (void)close;
+ (void)verbose: (const char*)tag message: (NSString*)message;
+ (void)debug: (const char*)tag message: (NSString*)message;
+ (void)info: (const char*)tag message: (NSString*)message;
+ (void)warning: (const char*)tag message: (NSString*)message;
+ (void)error: (const char*)tag message: (NSString*)message;
+ (void)fatal: (const char*)tag message: (NSString*)message;

@end
