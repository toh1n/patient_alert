package com.example.patient_alert;

import android.annotation.SuppressLint;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.Intent;
import android.content.SharedPreferences;
import android.media.AudioAttributes;
import android.os.Binder;
import android.os.IBinder;
import android.preference.PreferenceManager;
import android.content.Context;
import android.os.PowerManager;
import androidx.core.app.NotificationCompat;
import java.io.IOException;
import java.io.InputStream;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.UUID;


public class BluetoothService extends Service  {

    private PowerManager.WakeLock wakeLock;

    private final BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
    private BluetoothSocket bluetoothSocket;
    private final UUID MY_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB"); // Bluetooth Serial Port Profile

    private int notificationId = 5;

    public class LocalBinder extends Binder {
        BluetoothService getService() {
            return BluetoothService.this;
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return new LocalBinder();
    }

    @Override
    public void onCreate() {
        super.onCreate();
        PowerManager powerManager = (PowerManager) getSystemService(Context.POWER_SERVICE);
        wakeLock = powerManager.newWakeLock(
                PowerManager.FULL_WAKE_LOCK |
                        PowerManager.ACQUIRE_CAUSES_WAKEUP |
                        PowerManager.ON_AFTER_RELEASE,
                "MyApp::MyWakelockTag");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String deviceAddress = intent.getStringExtra("address");

        startForeground(1, createNotification("Bluetooth Service Started", "Running..."));


        new Thread(() -> connectAndListen(deviceAddress)).start();

        return START_STICKY;
    }

    @SuppressLint("NewApi")
    private Notification createNotification(String title, String message) {

        AudioAttributes audioAttributes = new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build();

        NotificationChannel channel = new NotificationChannel("channel_01", "Bluetooth Service", NotificationManager.IMPORTANCE_HIGH);
        channel.setSound(android.provider.Settings.System.DEFAULT_NOTIFICATION_URI, audioAttributes);
        channel.setImportance(NotificationManager.IMPORTANCE_HIGH);

        NotificationManager notificationManager = getSystemService(NotificationManager.class);
        notificationManager.createNotificationChannel(channel);


        return new NotificationCompat.Builder(this, "channel_01")
                .setContentTitle(title)
                .setContentText(message)
                .setSmallIcon(R.drawable.launch_background)
                .setSound(android.provider.Settings.System.DEFAULT_NOTIFICATION_URI)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .build();
    }



    private void saveNotification(String message) {
        if (message == null || message.trim().isEmpty()) {
            // Message is empty or null, so return without saving
            return;
        }
        SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this);
        SharedPreferences.Editor editor = sharedPreferences.edit();

        String existingNotifications = sharedPreferences.getString("all_notifications", "");

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        String currentDateAndTime = sdf.format(new Date());

        // Combine message, date, and time
        String updatedNotifications = existingNotifications + currentDateAndTime + " #" + message + "\n";

//        String updatedNotifications = existingNotifications + message + "\n";
        editor.putString("all_notifications", updatedNotifications);
        editor.apply();

    }

    @SuppressLint("MissingPermission")
    private void connectAndListen(String address) {
        BluetoothDevice device = bluetoothAdapter.getRemoteDevice(address);
        SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this);
        SharedPreferences.Editor editor = sharedPreferences.edit();

        try {
            bluetoothSocket = device.createRfcommSocketToServiceRecord(MY_UUID);
            bluetoothSocket.connect();
            if(bluetoothSocket.isConnected()){
                editor.putString("latest_message", address);
                editor.apply();
                showNotification("Device Connected", "Background service is started.");
            }
            InputStream inputStream = bluetoothSocket.getInputStream();

            byte[] buffer = new byte[1024];
            int bytesRead;


            while (true) {
                try {
                    bytesRead = inputStream.read(buffer);
                    String message = new String(buffer, 0, bytesRead);
                    if(!(message.equals(""))){
                        saveNotification(message);
                        showNotification("Alert", message);
                    }
                } catch (IOException | NullPointerException e) {
                    editor.putString("latest_message", "false");
                    editor.apply();
                    showNotification("Device Disconnected", "Bluetooth service is stopping.");
                    stopSelf();
                    break;
                }
            }
        } catch (IOException e) {
            editor.putString("latest_message", "false");
            editor.apply();
            showNotification("Failed to connect", "Bluetooth service is stopping.");
            stopSelf();
        }
    }

    private void showNotification(String title, String message) {
        // Acquire WakeLock
        wakeLock.acquire(10 * 60 * 1000L /*10 minutes*/);

        @SuppressLint({"NewApi", "LocalSuppress"}) NotificationManager notificationManager = getSystemService(NotificationManager.class);

        Notification notification = new NotificationCompat.Builder(this, "channel_01")
                .setContentTitle(title)
                .setContentText(message)
                .setSmallIcon(R.drawable.launch_background)
                .setSound(android.provider.Settings.System.DEFAULT_NOTIFICATION_URI)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .build();

        notificationManager.notify(notificationId++, notification);
        // Release WakeLock
        wakeLock.release();
    }

    public String getSavedNotifications() {
        SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this);
        return sharedPreferences.getString("all_notifications", "");
    }
    // Method to allow Flutter to fetch stored data
    public String getStoredMessage() {
        SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this);
        return sharedPreferences.getString("latest_message", "No message");
    }
}