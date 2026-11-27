# Release builds are shrunk by R8. WorkManager (the step readings every
# 15 minutes) keeps its jobs in a Room database whose generated class is
# found by name at start-up, so R8 must keep it, or the app crashes on
# launch with "Failed to create an instance of class
# androidx.work.impl.WorkDatabase".
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.room.RoomDatabase { <init>(...); }
-keep class com.naman9245.aurafit.StepWorker { <init>(...); }
