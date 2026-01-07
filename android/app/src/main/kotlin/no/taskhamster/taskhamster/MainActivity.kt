package no.taskhamster.taskhamster

import android.app.ActivityManager
import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.taskhamster.kiosk/control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "startLockTask" -> {
                        // Aktiverer Androids strengeste låsemodus (skjuler Home/Back/Statusbar)
                        startLockTask()
                        result.success(true)
                    }
                    "stopLockTask" -> {
                        // Deaktiverer låsen slik at man kan gå ut av appen
                        stopLockTask()
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                // Enterprise logging: Vi sender feilen tilbake til Flutter slik at den kan logges der
                result.error("KIOSK_ERROR", "Kunne ikke endre låsemodus: ${e.message}", null)
            }
        }
    }
}