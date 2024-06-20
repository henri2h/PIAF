package fr.henri2h.piaf

import android.os.Bundle
import android.os.StrictMode

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity(){
    override fun onCreate(savedInstanceState: Bundle?) {
        StrictMode.setThreadPolicy(
            StrictMode.ThreadPolicy.Builder()
                .detectDiskReads()
                .detectDiskWrites()
                .detectNetwork() // or .detectAll() for all detectable problems
                .penaltyLog()
                .build()
        )
        StrictMode.setVmPolicy(
         StrictMode.VmPolicy.Builder()
                .detectLeakedSqlLiteObjects()
                .detectLeakedClosableObjects()
                .penaltyLog()
                .penaltyDeath()
                .build()
        )
        super.onCreate(savedInstanceState)
    }
}
