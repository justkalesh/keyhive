package com.keyhive.keyhive

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

// IMPORTANT: FlutterFragmentActivity is required for biometric authentication
// to work properly with the local_auth package.
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // SECURITY: Prevent screenshots and screen recording
        // This adds FLAG_SECURE to the window, making the app's content
        // invisible in screenshots and recordings
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
