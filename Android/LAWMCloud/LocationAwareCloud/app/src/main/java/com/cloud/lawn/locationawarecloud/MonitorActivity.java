package com.cloud.lawn.locationawarecloud;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v7.app.ActionBarActivity;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.List;
import lecho.lib.hellocharts.gesture.ZoomType;
import lecho.lib.hellocharts.listener.ViewportChangeListener;
import lecho.lib.hellocharts.model.Axis;
import lecho.lib.hellocharts.model.AxisValue;
import lecho.lib.hellocharts.model.Column;
import lecho.lib.hellocharts.model.ColumnChartData;
import lecho.lib.hellocharts.model.SubcolumnValue;
import lecho.lib.hellocharts.model.Viewport;
import lecho.lib.hellocharts.util.ChartUtils;
import lecho.lib.hellocharts.view.ColumnChartView;
import lecho.lib.hellocharts.view.PreviewColumnChartView;

class MonitorDetails {
    String accessType;
    long size;
    long timeStamp;
    MonitorDetails(String accessType, long size, long timeStamp) {
        this.accessType = accessType;
        this.size = size;
        this.timeStamp = timeStamp;
    }
}
public class MonitorActivity extends ActionBarActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_monitor);
        if (savedInstanceState == null) {
            getSupportFragmentManager().beginTransaction().add(R.id.container, new PlaceholderFragment()).commit();
        }
    }

    /**
     * A placeholder fragment containing a simple view.
     */
    public static class PlaceholderFragment extends Fragment {

        private ColumnChartView chart;
        private PreviewColumnChartView previewChart;
        private ColumnChartData data;
        /**
         * Deep copy of data.
         */
        private ColumnChartData previewData;

        public PlaceholderFragment() {
        }

        @Override
        public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
            setHasOptionsMenu(true);
            View rootView = inflater.inflate(R.layout.fragment_monitor_chart, container, false);

            chart = (ColumnChartView) rootView.findViewById(R.id.chart);
            previewChart = (PreviewColumnChartView) rootView.findViewById(R.id.chart_preview);

            // Generate data for previewed chart and copy of that data for preview chart.
//            generateDefaultData();
            readData();
            chart.setColumnChartData(data);
            // Disable zoom/scroll for previewed chart, visible chart ranges depends on preview chart viewport so
            // zoom/scroll is unnecessary.
            chart.setZoomEnabled(false);
            chart.setScrollEnabled(false);

            previewChart.setColumnChartData(previewData);
            previewChart.setViewportChangeListener(new ViewportListener());

            previewX(false);

            return rootView;
        }

        // MENU
        @Override
        public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
            inflater.inflate(R.menu.preview_column_chart, menu);
        }

        @Override
        public boolean onOptionsItemSelected(MenuItem item) {
            int id = item.getItemId();
            if (id == R.id.action_reset) {
                generateDefaultData();
                chart.setColumnChartData(data);
                previewChart.setColumnChartData(previewData);
                previewX(true);
                return true;
            }
            if (id == R.id.action_preview_both) {
                previewXY();
                previewChart.setZoomType(ZoomType.HORIZONTAL_AND_VERTICAL);
                return true;
            }
            if (id == R.id.action_preview_horizontal) {
                previewX(true);
                return true;
            }
            if (id == R.id.action_preview_vertical) {
                previewY();
                return true;
            }
            if (id == R.id.action_change_color) {
                int color = ChartUtils.pickColor();
                while (color == previewChart.getPreviewColor()) {
                    color = ChartUtils.pickColor();
                }
                previewChart.setPreviewColor(color);
                return true;
            }
            return super.onOptionsItemSelected(item);
        }

        private void readData() {
            // Reading the data file
            int dataPointsCount = 0;
            ArrayList<MonitorDetails> list = new ArrayList<>();
            BufferedReader reader = null;
            try {
                reader = new BufferedReader(
                        new InputStreamReader(getContext().getAssets().open("monitor.txt"), "UTF-8"));

                // do reading, usually loop until end of file reading
                String mLine;
                String[] row = new String[4];
                Date time;

                while ((mLine = reader.readLine()) != null) {
                    //process line
                    row = mLine.split(",");
//                    time = new Date((long)Long.parseLong(row[3])*1000);
                    dataPointsCount += 1;

                    list.add(new MonitorDetails(row[0].trim(), Long.parseLong(row[2].trim())/1000000, Long.parseLong(row[3].trim())));

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

            // sort the monitor list
            Collections.sort(list, new Comparator<MonitorDetails>() {
                public int compare(MonitorDetails m1, MonitorDetails m2) {
                    if(m1.timeStamp > m2.timeStamp)
                        return 1;
                    else if(m1.timeStamp < m2.timeStamp)
                        return -1;
                    else
                        return 0;
                }
            });




            int numSubcolumns = 1;
            int numColumns = dataPointsCount;
            List<Column> columns = new ArrayList<Column>();
            List<SubcolumnValue> values;
            // create timeStamp list for x axis
            List<AxisValue> listTimeStamp= new ArrayList<>();
            for (int i = 0; i < numColumns; ++i) {

                values = new ArrayList<SubcolumnValue>();
                for (int j = 0; j < numSubcolumns; ++j) {
                    if (list.get(i).accessType.equals("upload")){
                        values.add(new SubcolumnValue((float) list.get(i).size, ChartUtils.COLOR_GREEN));
                    }
                    else{
                        values.add(new SubcolumnValue((float) list.get(i).size, ChartUtils.COLOR_RED));
                    }
                }
                Date d = new Date(list.get(i).timeStamp * 1000);
                listTimeStamp.add(new AxisValue(i).setLabel(new SimpleDateFormat("MM-dd").format(d)));
                columns.add(new Column(values));
            }

            data = new ColumnChartData(columns);
            //data.setAxisXBottom(new Axis());
            data.setAxisXBottom(new Axis(listTimeStamp).setHasLines(true).setName("Date"));

            data.setAxisYLeft(new Axis().setHasLines(true).setName("File Size (MB)"));

            // prepare preview data, is better to use separate deep copy for preview chart.
            // set color to grey to make preview area more visible.
            previewData = new ColumnChartData(data);
            for (Column column : previewData.getColumns()) {
                for (SubcolumnValue value : column.getValues()) {
                    value.setColor(ChartUtils.DEFAULT_DARKEN_COLOR);
                }
            }

            Viewport v = chart.getMaximumViewport();
            v.set(v.left, 4000, v.right, 0);
            chart.setMaximumViewport(v);
            chart.setCurrentViewport(v);

        }

        private void generateDefaultData() {
            int numSubcolumns = 1;
            int numColumns = 50;
            List<Column> columns = new ArrayList<Column>();
            List<SubcolumnValue> values;
            for (int i = 0; i < numColumns; ++i) {

                values = new ArrayList<SubcolumnValue>();
                for (int j = 0; j < numSubcolumns; ++j) {
                    values.add(new SubcolumnValue((float) Math.random() * 50f + 5, ChartUtils.pickColor()));
                }

                columns.add(new Column(values));
            }

            data = new ColumnChartData(columns);
            data.setAxisXBottom(new Axis());
            data.setAxisYLeft(new Axis().setHasLines(true));

            // prepare preview data, is better to use separate deep copy for preview chart.
            // set color to grey to make preview area more visible.
            previewData = new ColumnChartData(data);
            for (Column column : previewData.getColumns()) {
                for (SubcolumnValue value : column.getValues()) {
                    value.setColor(ChartUtils.DEFAULT_DARKEN_COLOR);
                }
            }

        }
        private void previewY() {
            Viewport tempViewport = new Viewport(chart.getMaximumViewport());
            float dy = tempViewport.height() / 4;
            tempViewport.inset(0, dy);
            previewChart.setCurrentViewportWithAnimation(tempViewport);
            previewChart.setZoomType(ZoomType.VERTICAL);
        }

        private void previewX(boolean animate) {
            Viewport tempViewport = new Viewport(chart.getMaximumViewport());
            float dx = tempViewport.width() / 4;
            tempViewport.inset(dx, 0);
            if (animate) {
                previewChart.setCurrentViewportWithAnimation(tempViewport);
            } else {
                previewChart.setCurrentViewport(tempViewport);
            }
            previewChart.setZoomType(ZoomType.HORIZONTAL);
        }

        private void previewXY() {
            // Better to not modify viewport of any chart directly so create a copy.
            Viewport tempViewport = new Viewport(chart.getMaximumViewport());
            // Make temp viewport smaller.
            float dx = tempViewport.width() / 4;
            float dy = tempViewport.height() / 4;
            tempViewport.inset(dx, dy);
            previewChart.setCurrentViewportWithAnimation(tempViewport);
        }

        /**
         * Viewport listener for preview chart(lower one). in {@link #onViewportChanged(Viewport)} method change
         * viewport of upper chart.
         */
        private class ViewportListener implements ViewportChangeListener {

            @Override
            public void onViewportChanged(Viewport newViewport) {
                // don't use animation, it is unnecessary when using preview chart because usually viewport changes
                // happens to often.
                chart.setCurrentViewport(newViewport);
            }

        }
    }
}
