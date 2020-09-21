package com.example.beacons_plugin_test

import io.flutter.embedding.android.FlutterActivity
import com.umair.beacons_plugin.BeaconsPlugin
import com.taras.taras_plugin_local.coloredMessage
import timber.log.Timber

class MainActivity: FlutterActivity() {

    companion object {

        @JvmStatic
        private val activityName = "Main Activity"
    }

    override fun onPause() {
        super.onPause()

        Timber.i(coloredMessage("${activityName} - Lifecyle: Pause", "Bright Pink"))

        //Start Background service to scan BLE devices
        BeaconsPlugin.startBackgroundService(this)
    }

    override fun onResume() {
        super.onResume()

        Timber.i(coloredMessage("${activityName} - Lifecyle: Resume", "Bright Pink"))

        //Stop Background service, app is in foreground
        BeaconsPlugin.stopBackgroundService(this)
    }
}
