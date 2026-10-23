package com.dacong.app;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.graphics.Bitmap;
import android.view.Gravity;
import android.view.View;
import android.webkit.SslErrorHandler;
import android.net.http.SslError;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.RenderProcessGoneDetail;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.ProgressBar;
import android.widget.Toast;
import androidx.activity.OnBackPressedCallback;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.splashscreen.SplashScreen;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import java.net.URI;
import java.io.InputStream;
import java.io.InputStreamReader;
import org.json.JSONObject;

public class MainActivity extends AppCompatActivity {
    static final String HOME_URL = "https://dacong-weld.vercel.app/web/dynamics";
    private WebView webView;
    private FrameLayout root;
    private LinearLayout errorView;
    private TextView message;
    private ProgressBar progress;
    private Button retry;
    private boolean pageFailed;
    private boolean fallbackMode;
    private int loadVersion;
    private String lastAppUrl = HOME_URL;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable loadTimeout = () -> showError("页面加载超时\n可以重试，或使用简版读取资讯");

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        SplashScreen.installSplashScreen(this);
        super.onCreate(savedInstanceState);
        root = new FrameLayout(this);
        errorView = new LinearLayout(this);
        errorView.setOrientation(LinearLayout.VERTICAL);
        errorView.setGravity(Gravity.CENTER);
        errorView.setBackgroundColor(android.graphics.Color.WHITE);
        progress = new ProgressBar(this);
        errorView.addView(progress);
        message = new TextView(this);
        message.setTextColor(android.graphics.Color.rgb(15, 23, 42));
        message.setGravity(Gravity.CENTER);
        message.setTextSize(18);
        errorView.addView(message);
        retry = new Button(this);
        retry.setText("重试完整版");
        retry.setOnClickListener(view -> loadFullPage(true));
        errorView.addView(retry);
        Button fallback = new Button(this);
        fallback.setText("查看简版资讯");
        fallback.setOnClickListener(view -> loadFallback());
        errorView.addView(fallback);
        root.addView(errorView, new FrameLayout.LayoutParams(-1, -1));
        setContentView(root);
        ViewCompat.setOnApplyWindowInsetsListener(root, (view, windowInsets) -> {
            Insets insets = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars()
                | WindowInsetsCompat.Type.displayCutout() | WindowInsetsCompat.Type.ime());
            view.setPadding(insets.left, insets.top, insets.right, insets.bottom);
            return windowInsets;
        });
        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                if (!fallbackMode && webView != null && webView.canGoBack()) webView.goBack();
                else finish();
            }
        });
        loadFullPage(false);
    }

    private void createWebView() {
        if (webView != null) return;
        webView = new WebView(this);
        root.addView(webView, 0, new FrameLayout.LayoutParams(-1, -1));
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setUseWideViewPort(true);
        settings.setLoadWithOverviewMode(true);
        settings.setAllowFileAccess(false);
        settings.setAllowContentAccess(false);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                if (isAppUrl(url)) {
                    fallbackMode = false;
                    lastAppUrl = url;
                    showLoading();
                }
            }

            @Override
            public void onPageCommitVisible(WebView view, String url) {
                confirmContent(view);
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                confirmContent(view);
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                if (isAppUrl(request.getUrl().toString())) return false;
                if (!request.isForMainFrame()) return true;
                String scheme = request.getUrl().getScheme();
                if ("https".equals(scheme) || "http".equals(scheme)) {
                    try {
                        startActivity(new Intent(Intent.ACTION_VIEW, request.getUrl()));
                    } catch (ActivityNotFoundException error) {
                        Toast.makeText(MainActivity.this, "未找到可打开链接的浏览器", Toast.LENGTH_SHORT).show();
                    }
                }
                return true;
            }

            @Override
            public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                if (request.isForMainFrame()) showError("暂时无法连接 AI 动态\n请检查网络，或使用简版读取资讯");
            }

            @Override
            public void onReceivedHttpError(WebView view, WebResourceRequest request, WebResourceResponse response) {
                if (request.isForMainFrame()) showError("页面暂时不可用（HTTP " + response.getStatusCode() + "）\n可以重试，或使用简版读取资讯");
            }

            @Override
            public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
                handler.cancel();
                showError("无法验证站点的安全连接\n请检查设备时间与网络后重试");
            }

            @Override
            public boolean onRenderProcessGone(WebView view, RenderProcessGoneDetail detail) {
                root.removeView(view);
                view.destroy();
                webView = null;
                showError("网页组件已停止\n可以重试，或使用简版读取资讯");
                return true;
            }
        });
    }

    private void showLoading() {
        pageFailed = false;
        loadVersion++;
        message.setText("正在加载 AI 动态…\nDaCong " + BuildConfig.VERSION_NAME);
        progress.setVisibility(View.VISIBLE);
        retry.setVisibility(View.GONE);
        errorView.setVisibility(View.VISIBLE);
        handler.removeCallbacks(loadTimeout);
        handler.postDelayed(loadTimeout, 20_000);
    }

    private void showError(String text) {
        pageFailed = true;
        handler.removeCallbacks(loadTimeout);
        message.setText(text);
        progress.setVisibility(View.GONE);
        retry.setVisibility(View.VISIBLE);
        errorView.setVisibility(View.VISIBLE);
    }

    private void confirmContent(WebView view) {
        if (pageFailed || view != webView) return;
        int version = loadVersion;
        view.evaluateJavascript("!!(document.body && document.body.innerText.trim().length)", result -> {
            if (!pageFailed && view == webView && version == loadVersion && "true".equals(result)) {
                handler.removeCallbacks(loadTimeout);
                errorView.setVisibility(View.GONE);
            }
        });
    }

    private void loadFullPage(boolean clearCache) {
        createWebView();
        webView.stopLoading();
        if (clearCache) webView.clearCache(true);
        fallbackMode = false;
        showLoading();
        webView.loadUrl(lastAppUrl);
    }

    private void loadFallback() {
        createWebView();
        webView.stopLoading();
        fallbackMode = true;
        showLoading();
        try (InputStream stream = getResources().openRawResource(R.raw.news_fallback);
             InputStreamReader reader = new InputStreamReader(stream, java.nio.charset.StandardCharsets.UTF_8)) {
            StringBuilder html = new StringBuilder();
            char[] buffer = new char[4096];
            int count;
            while ((count = reader.read(buffer)) != -1) html.append(buffer, 0, count);
            String config = new JSONObject().put("url", BuildConfig.NEWS_API_URL).put("key", BuildConfig.NEWS_PUBLIC_KEY).toString();
            webView.loadDataWithBaseURL(BuildConfig.NEWS_API_URL + "/app/", html.toString().replace("__PUBLIC_NEWS_CONFIG__", config), "text/html", "UTF-8", null);
        } catch (java.io.IOException | org.json.JSONException error) {
            showError("无法打开简版资讯，请重试");
        }
    }

    static boolean isAppUrl(String url) {
        try {
            URI uri = URI.create(url);
            return "https".equalsIgnoreCase(uri.getScheme())
                && "dacong-weld.vercel.app".equalsIgnoreCase(uri.getHost())
                && uri.getRawUserInfo() == null && (uri.getPort() == -1 || uri.getPort() == 443);
        } catch (IllegalArgumentException error) {
            return false;
        }
    }

    @Override
    protected void onDestroy() {
        handler.removeCallbacksAndMessages(null);
        if (webView != null) {
            root.removeView(webView);
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }
}
