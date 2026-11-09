## 1.0.0-dev.4

- Development prerelease of the `package:logging` integration for Mars.
- Supersedes the earlier Flutter plugin layout published as `1.0.0-dev.0`–`1.0.0-dev.3`:
  the integration is plain Dart and depends directly on `package:mars` instead
  of the `mars_logging_platform_interface` / `_android` / `_darwin` packages.
- Adds `Xlog.onRecord`, which forwards `package:logging` records to the Mars
  XLog logger: `loggerName` becomes the xlog tag, levels map ascending as
  FINE/FINER/FINEST → verbose, CONFIG → debug, INFO → info, WARNING → warn,
  SEVERE → error, SHOUT → fatal, and `error` / `stackTrace` are appended to
  the message.
- Depends on `package:mars` (`^1.0.0-dev.0`); the Mars API is **not**
  re-exported — import `package:mars` alongside this package.
- Note: this is a prerelease — the API surface may change in breaking ways
  before 1.0.0.
