/**
 * Merged ImportLibs for the single-lib layout.
 *
 * Upstream defines two ImportLibs() in two shared libraries:
 *   - marsxlog (libraries/mars_xlog_sdk/jni/import.cc)   -> ExportXlog()
 *   - marsstn (libraries/mars_android_sdk/jni/import.cc) -> ExportSTN(), ExportBaseEvent(), ExportSDT()
 * They never conflict because each lives in its own DSO.
 *
 * This package links every module into ONE shared library (libmars.so), so
 * only a single ImportLibs() definition is allowed. This file merges the two
 * upstream import.cc into one, keeping the same set of Export* triggers.
 * ExportXlog() is an empty marker function (Java2C_Xlog.cc), so merging it
 * here carries no extra behavior.
 */

void ImportLibs() {
    extern void ExportSTN();
    ExportSTN();

    extern void ExportBaseEvent();
    ExportBaseEvent();

    extern void ExportSDT();
    ExportSDT();

    extern void ExportXlog();
    ExportXlog();
}
