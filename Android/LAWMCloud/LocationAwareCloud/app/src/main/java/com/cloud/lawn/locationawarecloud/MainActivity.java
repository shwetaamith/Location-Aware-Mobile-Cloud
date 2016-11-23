package com.cloud.lawn.locationawarecloud;

import android.content.DialogInterface;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.content.Intent;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.Date;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        Button upload = (Button) findViewById(R.id.upload);
        Button download = (Button) findViewById(R.id.download);
        Button monitor = (Button) findViewById(R.id.bt_Monitor);


    }

    public void downloadMe(View v)
    {
//        Toast toast = Toast.makeText(v.getContext(), "text", Toast.LENGTH_SHORT);
//        toast.show();

//        Intent i = new Intent(MainActivity.this, WebAppActivity.class);
        Intent i = getPackageManager().getLaunchIntentForPackage("com.cloudapp.lawm");
        v.getContext().startActivity(i);
        BufferedReader reader = null;
        String result = "Device Name     " + '\t' + "Distance(miles)" + '\n';
        try {
            reader = new BufferedReader(
                    new InputStreamReader(v.getContext().getAssets().open("DeviceLocation.txt"), "UTF-8"));

            // do reading, usually loop until end of file reading
            String mLine;


            while ((mLine = reader.readLine()) != null) {
                //process line
                String s[] = mLine.split(",");
                result += s[0] + "          " + s[1] + '\n';


            }
        } catch (IOException e) {
            //log the exception
            Log.w("READDATA", "FILE NOT READ: "+ e.getMessage());
        } finally {
            if (reader != null) {
                try {
                    reader.close();
                } catch (IOException e) {
                    //log the exception
                }
            }
        }

        AlertDialog.Builder builder1 = new AlertDialog.Builder(v.getContext());
        builder1.setMessage(result);
        builder1.setCancelable(true);

        builder1.setPositiveButton(
                "Yes",
                new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        dialog.cancel();
                    }
                });

        builder1.setNegativeButton(
                "No",
                new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        dialog.cancel();
                    }
                });

        try {
            Thread.sleep(10000);

            Intent wifidirectIntent = getPackageManager().getLaunchIntentForPackage("com.example.android.wifidirect");
            startActivity(wifidirectIntent);
//            AlertDialog alert11 = builder1.create();
//            alert11.show();
//            Intent showDeviceListIntent = new Intent(v.getContext(), DeviceListActivity.class);
//            startActivity(showDeviceListIntent);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

    }

    public void displayMonitor(View v)
    {
        Intent i = new Intent(MainActivity.this, MonitorActivity.class);
        startActivity(i);
    }

    public void uploadMe(View v)
    {
        Intent i = getPackageManager().getLaunchIntentForPackage("com.cloudapp.lawm");
        startActivity(i);
    }

}
