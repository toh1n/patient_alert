package com.example.patient_alert;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.preference.PreferenceManager;
import android.provider.Settings;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import org.json.JSONArray;
import org.json.JSONException;


public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.patient_alert/bluetooth";


    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if(call.method.equals("startService")) {
                        String address = call.argument("address");
                        Intent intent = new Intent(this, BluetoothService.class);
                        intent.putExtra("address", address);
                        startService(intent);
                        result.success("gf");

                    } else if (call.method.equals("getStoredMessage")) {

                        SharedPreferences sharedPreferences = android.preference.PreferenceManager.getDefaultSharedPreferences(this);
                        String message = sharedPreferences.getString("latest_message", "No message");
                        result.success(message);

                    }  else if (call.method.equals("getNotifications")) {
                        SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this);
                        String notifications = sharedPreferences.getString("all_notifications", "");;
                        result.success(notifications);
                    } else if (call.method.equals("clearPrefs")) {
                        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(this);
                        SharedPreferences.Editor editor = preferences.edit();
                        editor.remove("all_notifications");
                        editor.apply();
                        result.success(true);
                    } else if (call.method.equals("openAppSettings")) {
                        Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                        Uri uri = Uri.fromParts("package", getPackageName(), null);
                        intent.setData(uri);
                        startActivity(intent);
                    }
                    else {
                        result.notImplemented();
                    }
                });
    }
}
