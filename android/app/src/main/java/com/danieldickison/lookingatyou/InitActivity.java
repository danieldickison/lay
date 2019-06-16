package com.danieldickison.lookingatyou;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;

public class InitActivity extends Activity {

    private final static String HOST_KEY = "com.danieldickison.lay.host";
    private final static String TABLET_NUMBER_KEY = "com.danieldickison.lay.tablet_number";
    private final static String DEFAULT_HOST = "10.1.1.200";

    private EditText serverIP;
    private EditText tabletNumber;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_init);

        Button connectButton = findViewById(R.id.connect_button);
        connectButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                startWebViewActivity();
            }
        });

        serverIP = findViewById(R.id.server_ip);
        tabletNumber = findViewById(R.id.tablet_number);

        SharedPreferences prefs = getPreferences(0);
        serverIP.setText(prefs.getString(HOST_KEY, DEFAULT_HOST));
        int n = prefs.getInt(TABLET_NUMBER_KEY, -1);
        if (n != -1) {
            tabletNumber.setText(Integer.toString(n));
        }
    }

    private void startWebViewActivity() {
        String host = serverIP.getText().toString();
        int number = Integer.parseInt(tabletNumber.getText().toString());
        SharedPreferences.Editor prefs = getPreferences(0).edit();
        prefs.putString(HOST_KEY, host);
        prefs.putInt(TABLET_NUMBER_KEY, number);
        prefs.apply();

        Intent intent = new Intent(this, WebViewActivity.class);
        intent.putExtra(WebViewActivity.HOST_EXTRA, host);
        intent.putExtra(WebViewActivity.TABLET_NUMBER_EXTRA, number);
        startActivity(intent);
    }
}
