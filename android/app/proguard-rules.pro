# R8 keep rules for Kotlin classes looked up through JNI by package:jni /
# Pigeon in shared_preferences_android 2.5.x.
# Upstream fix (not yet in the published package):
# https://github.com/flutter/packages/pull/13311
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }
