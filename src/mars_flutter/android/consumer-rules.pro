-keep class com.sun.jna.** { *; }
-keep interface dev.invictus_dart.mars_flutter.MarsLibrary { *; }

# JNA references java.awt.* (via com.sun.jna.Native$AWT) which does not exist on Android.
# These references are never exercised on Android, so silence the R8 missing-class warnings.
-dontwarn java.awt.Component
-dontwarn java.awt.GraphicsEnvironment
-dontwarn java.awt.HeadlessException
-dontwarn java.awt.Window
