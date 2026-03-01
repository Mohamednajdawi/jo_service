# Google Sign-In Setup (Production)

The app uses **production** API (`https://joservice-production.up.railway.app`). Google login will fail with **"Google OAuth is not configured"** until the backend has a Google Client ID set.

## Create iOS OAuth client (Google Cloud Console)

1. Go to [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**.
2. Click **Create Credentials** → **OAuth client ID**.
3. Application type: **iOS**.
4. **Name:** e.g. `iOS client 1`.
5. **Bundle ID** (required): use your app’s bundle ID exactly:
   ```
   com.mohammadnajdawi.joserviceapp2025
   ```
6. **App Store ID** and **Team ID**: leave empty unless you’re publishing.
7. Click **Create**. Copy the **Client ID** (you’ll use it in Railway and in the Flutter app if needed).

## Fix: Set env var on Railway

1. **Get your Google Client ID**  
   Use the same OAuth 2.0 Client ID you use for the Flutter app (from [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials).  
   It looks like: `xxxxx-xxxxx.apps.googleusercontent.com`

2. **Add it to Railway**
   - Open your project on [Railway](https://railway.app/)
   - Select the **JO Service backend** service
   - Go to **Variables**
   - Add:
     - **Name:** `GOOGLE_CLIENT_ID`
     - **Value:** your Client ID (e.g. `912520355771-xxxx.apps.googleusercontent.com`)
   - Save / redeploy if needed

3. **Redeploy**  
   If the server was already running, trigger a redeploy so it picks up the new variable (or wait for the next deploy).

After that, Google sign-in from the app should work against production.

## Local development

Put the same value in `server/.env`:

```bash
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
```

`GOOGLE_CLIENT_SECRET` is **not** required for the current mobile flow (the server only verifies the ID token with Google).
