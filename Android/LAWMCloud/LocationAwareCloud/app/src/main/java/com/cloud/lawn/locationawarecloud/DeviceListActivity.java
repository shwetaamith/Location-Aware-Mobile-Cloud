package com.cloud.lawn.locationawarecloud;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.Toast;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

/**
 * Created by incyphae10 on 11/2/16.
 */
public class DeviceListActivity extends Activity {
    ListView listView ;
    BufferedReader reader = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_device_list);

        // Get ListView object from xml
        listView = (ListView) findViewById(R.id.deviceslist);
        String[] result = new String[4];
        try {
            reader = new BufferedReader(
                    new InputStreamReader(getAssets().open("DeviceLocation.txt"), "UTF-8"));

            // do reading, usually loop until end of file reading
            String mLine;
            int i = 0;

            while ((mLine = reader.readLine()) != null) {
                //process line
                String s[] = mLine.split(",");
                result[i++] = s[0] + '-' +s[1];


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

        // Defined Array values to show in ListView


        // Define a new Adapter
        // First parameter - Context
        // Second parameter - Layout for the row
        // Third parameter - ID of the TextView to which the data is written
        // Forth - the Array of data

        ArrayAdapter<String> adapter = new ArrayAdapter<String>(this,
                android.R.layout.simple_list_item_1, android.R.id.text1, result);


        // Assign adapter to ListView
        listView.setAdapter(adapter);

        // ListView Item Click Listener
        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {

            @Override
            public void onItemClick(AdapterView<?> parent, View view,
                                    int position, long id) {

                // ListView Clicked item index
                int itemPosition     = position;

                // ListView Clicked item value
                String  itemValue    = (String) listView.getItemAtPosition(position);

                // Show Alert
                Toast.makeText(getApplicationContext(),
                        "Position :"+itemPosition+"  ListItem : " +itemValue , Toast.LENGTH_LONG)
                        .show();

            }

        });


        try {
            Thread.sleep(10000);
            Intent i = getPackageManager().getLaunchIntentForPackage("com.example.android.wifidirect");
            startActivity(i);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

}