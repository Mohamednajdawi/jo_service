# Verification Services Setup Guide

This guide will help you set up the verification services for the JO Service marketplace.

## Current Status

✅ **Working**: 
- User registration and login
- Basic verification flow
- Mock email and SMS services (for development)

❌ **Not Working**:
- Real email verification (Gmail not configured)
- Real SMS verification (Twilio not configured)
- Google/Facebook OAuth (credentials not configured)

## Quick Fix for Development

### 1. Update your .env file

Add these lines to your `server/.env` file:

```bash
# Email Configuration (Gmail)
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
FRONTEND_URL=http://localhost:3000

# SMS Configuration (Twilio)
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=+1234567890

# OAuth Configuration
FACEBOOK_APP_ID=your-facebook-app-id
FACEBOOK_APP_SECRET=your-facebook-app-secret
FACEBOOK_REDIRECT_URI=http://localhost:3000/api/auth/oauth/facebook/callback

GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REDIRECT_URI=http://localhost:3000/api/auth/oauth/google/callback
```

### 2. How to Get Verification Codes (Development Mode)

**Without configuring real services:**

1. **Email Verification**: Check your server console logs for the verification token
2. **SMS Verification**: Check your server console logs for the 6-digit code
3. **OAuth**: Will show "not configured" error until you add credentials

## Setting Up Real Services

### Email Verification (Gmail)

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate App Password**:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate a new app password for "JO Service"
3. **Update .env**:
   ```bash
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASS=your-16-digit-app-password
   ```

### SMS Verification (Twilio)

1. **Create Twilio Account** at [twilio.com](https://twilio.com)
2. **Get Credentials**:
   - Account SID
   - Auth Token
   - Phone number
3. **Update .env**:
   ```bash
   TWILIO_ACCOUNT_SID=your-account-sid
   TWILIO_AUTH_TOKEN=your-auth-token
   TWILIO_PHONE_NUMBER=+1234567890
   ```

### Google OAuth

1. **Create Google Cloud Project** at [console.cloud.google.com](https://console.cloud.google.com)
2. **Enable OAuth 2.0 API**
3. **Create OAuth 2.0 Credentials**:
   - Client ID
   - Client Secret
4. **Update .env**:
   ```bash
   GOOGLE_CLIENT_ID=your-client-id
   GOOGLE_CLIENT_SECRET=your-client-secret
   GOOGLE_REDIRECT_URI=http://localhost:3000/api/auth/oauth/google/callback
   ```

### Facebook OAuth

1. **Create Facebook App** at [developers.facebook.com](https://developers.facebook.com)
2. **Configure OAuth Settings**:
   - Valid OAuth Redirect URIs
   - App ID and Secret
3. **Update .env**:
   ```bash
   FACEBOOK_APP_ID=your-app-id
   FACEBOOK_APP_SECRET=your-app-secret
   FACEBOOK_REDIRECT_URI=http://localhost:3000/api/auth/oauth/facebook/callback
   ```

## Testing

### Test Email Verification

1. **Start the server**:
   ```bash
   npm run dev
   ```

2. **Register a new user** via API or Flutter app
3. **Check server logs** for email sending status
4. **Verify email** by clicking the link or using the token

### Test SMS Verification

1. **Register with phone number**
2. **Check server logs** for SMS code
3. **Verify phone** with the code

### Test OAuth

1. **Initiate OAuth flow**:
   ```bash
   GET /api/auth/oauth/facebook/initiate
   GET /api/auth/oauth/google/initiate
   ```

2. **Complete OAuth flow** via callback URLs

## Troubleshooting

### Common Issues

1. **"Email credentials not configured"**
   - Add EMAIL_USER and EMAIL_PASS to .env
   - Ensure Gmail 2FA is enabled
   - Use app password, not regular password

2. **"Twilio credentials not configured"**
   - Add TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN to .env
   - Ensure Twilio account has credits
   - Verify phone number format (E.164)

3. **"OAuth not configured"**
   - Add respective OAuth credentials to .env
   - Ensure redirect URIs match exactly
   - Check app settings in provider console

### Development vs Production

**Development**:
- Use mock services when possible
- Log verification codes to console
- Use localhost URLs for testing

**Production**:
- Use real email/SMS services
- Implement proper error handling
- Use production URLs and domains
- Enable comprehensive logging

## Next Steps

1. **Configure at least one real service** (email recommended)
2. **Test the complete verification flow**
3. **Implement OAuth user creation** in the callback
4. **Add verification analytics** and reporting
5. **Implement advanced anti-fraud** measures

## Support

For issues with verification services:

1. Check server logs for detailed error messages
2. Verify environment variables are set correctly
3. Test individual services independently
4. Review service provider documentation
5. Check network connectivity and firewall settings

## Current Mock Behavior

When services are not configured:

- **Email**: Logs verification token to console
- **SMS**: Logs 6-digit code to console  
- **OAuth**: Returns "not configured" error

This allows development to continue while you set up real services.
