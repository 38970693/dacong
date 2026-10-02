package com.dacong.app;

import org.junit.Test;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

public class NavigationTest {
    @Test
    public void keepsDynamicsDigestsAndLoginInApp() {
        assertTrue(MainActivity.isAppUrl(MainActivity.HOME_URL));
        assertTrue(MainActivity.isAppUrl("https://dacong-weld.vercel.app/web/digests/2026-10-02"));
        assertTrue(MainActivity.isAppUrl("https://dacong-weld.vercel.app:443/web/auth/login"));
    }

    @Test
    public void rejectsOtherOriginsAndUnsafeSchemes() {
        assertFalse(MainActivity.isAppUrl("https://www.technologyreview.com/story"));
        assertFalse(MainActivity.isAppUrl("https://dacong-weld.vercel.app.evil.example/web/dynamics"));
        assertFalse(MainActivity.isAppUrl("https://dacong-weld.vercel.app@evil.example"));
        assertFalse(MainActivity.isAppUrl("https://evil.example@dacong-weld.vercel.app"));
        assertFalse(MainActivity.isAppUrl("https://dacong-weld.vercel.app:8443"));
        assertFalse(MainActivity.isAppUrl("http://dacong-weld.vercel.app"));
        assertFalse(MainActivity.isAppUrl("javascript:alert(1)"));
        assertFalse(MainActivity.isAppUrl("file:///sdcard/index.html"));
        assertFalse(MainActivity.isAppUrl("invalid url"));
    }
}
