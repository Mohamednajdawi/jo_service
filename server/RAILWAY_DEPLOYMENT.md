# Railway Deployment Guide

This guide explains how to deploy the JO Service backend to Railway with Resend for email verification.

## Prerequisites

1. **Railway Account**: Sign up at [railway.app](https://railway.app)
2. **MongoDB Atlas**: Create a free cluster at [mongodb.com](https://www.mongodb.com/cloud/atlas)
3. **Resend Account**: Sign up at [resend.com](https://resend.com) for email services
4. **GitHub Repository**: Push your code to GitHub

## Step 1: Set Up MongoDB Atlas

1. Create a new cluster (free tier is fine for development)
2. Create a database user with read/write permissions
3. Whitelist all IPs (0.0.0.0/0) for Railway access
4. Get your connection string from "Connect" > "Connect your application"

## Step 2: Configure Resend

1. Create a Resend account at [resend.com](https://resend.com)
2. Get your API key from the dashboard
3. (Optional) Verify your domain for custom sender email
   - For testing, you can use `onboarding@resend.dev` as the sender

## Step 3: Deploy to Railway

### Option A: Deploy from GitHub (Recommended)

1. Push your code to GitHub
2. Go to [railway.app](https://railway.app) and sign in
3. Click "New Project" > "Deploy from GitHub repo"
4. Select your repository
5. Railway will auto-detect the Dockerfile

### Option B: Deploy with Railway CLI

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login to Railway
railway login

# Initialize project
railway init

# Deploy
railway up
```

## Step 4: Configure Environment Variables

In Railway dashboard, go to your service > Variables and add:

| Variable | Description | Example |
|----------|-------------|---------|
| `MONGODB_URI` | MongoDB Atlas connection string | `mongodb+srv://user:pass@cluster.mongodb.net/jo_service` |
| `JWT_SECRET` | Random secret for JWT tokens | `your-random-secret-key-here` |
| `JWT_EXPIRES_IN` | Token expiration time | `7d` |
| `NODE_ENV` | Environment mode | `production` |
| `RESEND_API_KEY` | Resend API key | `re_xxxxxxxxxxxx` |
| `EMAIL_FROM` | Sender email address | `noreply@yourdomain.com` |
| `FRONTEND_URL` | Your frontend URL | `https://your-frontend.vercel.app` |

### Optional Variables

| Variable | Description |
|----------|-------------|
| `GOOGLE_CLIENT_ID` | Google OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth secret |
| `TWILIO_ACCOUNT_SID` | Twilio account SID |
| `TWILIO_AUTH_TOKEN` | Twilio auth token |
| `TWILIO_PHONE_NUMBER` | Twilio phone number |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_PRIVATE_KEY` | Firebase private key |
| `FIREBASE_CLIENT_EMAIL` | Firebase client email |

## Step 5: Generate Domain

1. In Railway dashboard, go to Settings > Domains
2. Click "Generate Domain" for a free `.up.railway.app` subdomain
3. Or add a custom domain

## Step 6: Update CORS (Optional)

If you need to restrict CORS, update the CORS configuration in `src/app.js`:

```javascript
app.use(cors({
    origin: ['https://your-frontend.com', 'http://localhost:3000'],
    credentials: true
}));
```

## File Storage Warning

**Important**: Railway uses ephemeral filesystem. Files uploaded to `public/uploads/` will be lost on each deployment.

### Solutions:
1. **Railway Volumes**: Attach a persistent volume
2. **Cloud Storage**: Use AWS S3, Cloudinary, or similar
3. **Database**: Store small files directly in MongoDB

## Monitoring & Logs

- View logs in Railway dashboard > Deployments
- Set up health checks in Settings > Healthcheck
- Configure alerts for failed deployments

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check `MONGODB_URI` is correct
   - Ensure IP whitelist includes 0.0.0.0/0 in Atlas

2. **Email Not Sending**
   - Verify `RESEND_API_KEY` is correct
   - Check sender email is verified in Resend dashboard

3. **WebSocket Connection Issues**
   - Ensure your frontend connects to the correct Railway URL
   - Use `wss://` for secure WebSocket connections

4. **CORS Errors**
   - Add your frontend URL to allowed origins
   - Check browser console for specific error

## Quick Reference Commands

```bash
# View logs
railway logs

# Open Railway shell
railway shell

# Run commands in container
railway run npm install

# Check status
railway status
```

## Environment Variables Checklist

Before deploying, ensure you have:

- [ ] MongoDB Atlas cluster created
- [ ] MongoDB connection string (`MONGODB_URI`)
- [ ] JWT secret generated
- [ ] Resend account created
- [ ] Resend API key (`RESEND_API_KEY`)
- [ ] Sender email configured (`EMAIL_FROM`)
- [ ] Frontend URL set (`FRONTEND_URL`)
