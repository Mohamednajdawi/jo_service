# GitHub Secrets & Environment Variables

This guide explains **which variables to add** and **where** (GitHub vs Railway).

---

## 1. GitHub Actions Secrets & Variables (for CI/CD)

These are used by the workflows. They are **not** sent to Railway automatically; the running app gets its config from **Railway’s Variables** (see section 2).

### Repository variable: `jo_service_env`

If you created a **variable** named **`jo_service_env`** (Settings → Secrets and variables → Actions → **Variables** tab):

- **What it’s for:** The CI workflow uses it to create `server/.env` before running backend tests, so tests that need `JWT_SECRET`, etc. (e.g. `jwt.utils.test.js`) can run.
- **Format:** Paste your full `.env` contents (same format as `server/.env`), e.g.:
  ```env
  JWT_SECRET=your_test_secret
  JWT_EXPIRES_IN=1h
  MONGODB_URI=mongodb://...
  ```
- **In the workflow:** It’s referenced as `vars.jo_service_env`. The step “Load jo_service_env into .env” runs only when this variable is set.
- **Note:** Variables are not encrypted. Don’t put production secrets in `jo_service_env`; use test/sample values for CI, and keep real secrets in **Secrets** or in Railway.

### How to add GitHub Secrets

1. Open your repo: **https://github.com/Mohamednajdawi/jo_service**
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Enter **Name** and **Value**, then save

### Required for CD (deploy to Railway)

| Secret Name       | Description                    | Example / Where to get it                    |
|-------------------|--------------------------------|----------------------------------------------|
| `RAILWAY_TOKEN`   | Railway API token for deploy   | Railway Dashboard → Account → Tokens → Create |

Without `RAILWAY_TOKEN`, the CD workflow cannot run `railway deploy`.

### Optional (used only if you reference them in workflows later)

| Secret Name           | Description              |
|-----------------------|--------------------------|
| `FLUTTER_BUILD_NAME`  | App version name for APK |
| `CODECOV_TOKEN`       | If you enable Codecov in CI |

---

## 2. Railway Project Variables (for the running backend)

The **backend app on Railway** reads its config from **Railway’s Variables**, not from GitHub Secrets. Set these in the Railway project that runs your Node server.

### How to add Railway Variables

1. Go to **https://railway.app** and open your project (e.g. `jo_service` / `joservice-production`)
2. Select the **backend service**
3. Open the **Variables** tab
4. Add each variable (name + value) or use **Raw Editor** to paste many at once

### Variables to set in Railway

Copy from your local `server/.env` or use the list below. Replace placeholders with your real values.

| Variable             | Required | Description |
|----------------------|----------|-------------|
| `MONGODB_URI`        | Yes      | MongoDB connection string (e.g. from MongoDB Atlas or Railway MongoDB) |
| `JWT_SECRET`         | Yes      | Strong random string for JWT signing |
| `JWT_EXPIRES_IN`     | No       | e.g. `7d` (default used if missing) |
| `PORT`               | No       | Railway often sets this automatically |
| `NODE_ENV`           | No       | e.g. `production` |
| `APP_URL`            | Yes      | Backend URL, e.g. `https://joservice-production.up.railway.app` |
| `FRONTEND_URL`       | No       | Frontend / app URL if you use CORS or links |
| `RESEND_API_KEY`     | If email | From Resend dashboard (email sending) |
| `EMAIL_FROM`         | If email | Sender email for Resend |
| `GOOGLE_CLIENT_ID`   | If OAuth | Google Cloud Console → Credentials → OAuth 2.0 Client ID |
| `GOOGLE_CLIENT_SECRET` | If OAuth | Same app → Client secret |
| `TWILIO_ACCOUNT_SID` | If SMS   | Twilio console |
| `TWILIO_AUTH_TOKEN`  | If SMS   | Twilio console |
| `TWILIO_PHONE_NUMBER`| If SMS   | Twilio phone number |
| `FIREBASE_PROJECT_ID`| If push  | Firebase project ID |
| `FIREBASE_PRIVATE_KEY` | If push | Firebase service account private key |
| `FIREBASE_CLIENT_EMAIL` | If push | Firebase service account client email |

---

## 3. Summary

- **GitHub (Settings → Secrets and variables → Actions)**  
  - **Variables:** **`jo_service_env`** – optional; used by CI to create `server/.env` before backend tests (use test/sample values).  
  - **Secrets:** Add **`RAILWAY_TOKEN`** so the CD workflow can deploy to Railway. Add any other secrets only if you use them in workflow steps (e.g. `FLUTTER_BUILD_NAME`, `CODECOV_TOKEN`).

- **Railway (Project → Service → Variables)**  
  - Add all **backend environment variables** here (e.g. `MONGODB_URI`, `JWT_SECRET`, `APP_URL`, Resend, Google, Twilio, Firebase) so the running app has the correct config.

After adding `RAILWAY_TOKEN` in GitHub and the variables in Railway, pushes to `main` will run the CD workflow and deploy the backend.
