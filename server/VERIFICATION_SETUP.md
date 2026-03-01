# Verification Services Setup Guide

This guide explains how to set up the verification services for the JO Service marketplace to prevent fake accounts and ensure user authenticity.

## 1. Email Verification Setup

### Gmail Setup (Recommended for Development)

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate App Password**:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate a new app password for "JO Service"
3. **Set Environment Variables**:
   ```bash
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASS=your-16-digit-app-password
   FRONTEND_URL=http://localhost:3000
   ```

### Alternative Email Services

- **SendGrid**: Professional email service with high deliverability
- **Mailgun**: Developer-friendly email service
- **AWS SES**: Cost-effective for high volume

## 2. SMS Verification Setup

### Twilio Setup (Recommended)

1. **Create Twilio Account** at [twilio.com](https://twilio.com)
2. **Get Credentials**:
   - Account SID
   - Auth Token
   - Phone number
3. **Set Environment Variables**:
   ```bash
   TWILIO_ACCOUNT_SID=your-account-sid
   TWILIO_AUTH_TOKEN=your-auth-token
   TWILIO_PHONE_NUMBER=+1234567890
   ```

### Alternative SMS Services

- **AWS SNS**: Cost-effective for high volume
- **Vonage (Nexmo)**: Global coverage
- **MessageBird**: European provider

## 3. OAuth Integration Setup

### Facebook OAuth

1. **Create Facebook App** at [developers.facebook.com](https://developers.facebook.com)
2. **Configure OAuth Settings**:
   - Valid OAuth Redirect URIs
   - App ID and Secret
3. **Set Environment Variables**:
   ```bash
   FACEBOOK_APP_ID=your-app-id
   FACEBOOK_APP_SECRET=your-app-secret
   FACEBOOK_REDIRECT_URI=http://localhost:3000/api/auth/oauth/facebook/callback
   ```

### Google OAuth

1. **Create Google Cloud Project** at [console.cloud.google.com](https://console.cloud.google.com)
2. **Enable OAuth 2.0 API**
3. **Create OAuth 2.0 Credentials**:
   - Client ID
   - Client Secret
4. **Set Environment Variables**:
   ```bash
   GOOGLE_CLIENT_ID=your-client-id
   GOOGLE_CLIENT_SECRET=your-client-secret
   GOOGLE_REDIRECT_URI=http://localhost:3000/api/auth/oauth/google/callback
   ```

## 4. Environment Configuration

Create a `.env` file in the server directory:

```bash
# Copy from env.example
cp env.example .env

# Edit with your actual values
nano .env
```

## 5. Testing Verification Services

### Test Email Verification

1. **Start the server**:
   ```bash
   npm run dev
   ```

2. **Register a new user** via API
3. **Check server logs** for email sending status
4. **Verify email** by clicking the link

### Test SMS Verification

1. **Register with phone number**
2. **Check server logs** for SMS code
3. **Verify phone** with the code

### Test OAuth (When Implemented)

1. **Initiate OAuth flow**:
   ```bash
   GET /api/auth/oauth/facebook/initiate
   GET /api/auth/oauth/google/initiate
   ```

2. **Complete OAuth flow** via callback URLs

## 6. Production Considerations

### Security

- **Use HTTPS** for all OAuth redirects
- **Validate OAuth state tokens** to prevent CSRF
- **Store sensitive tokens** in secure environment variables
- **Implement rate limiting** for verification endpoints

### Scalability

- **Use Redis** for storing verification tokens
- **Implement token expiration** and cleanup
- **Use queue systems** for high-volume email/SMS sending

### Monitoring

- **Track verification success rates**
- **Monitor email/SMS delivery rates**
- **Log verification attempts** for security analysis

## 7. Troubleshooting

### Email Issues

- **Check Gmail app password** is correct
- **Verify 2FA is enabled** on Gmail account
- **Check spam folder** for verification emails
- **Review server logs** for SMTP errors

### SMS Issues

- **Verify Twilio credentials** are correct
- **Check phone number format** (E.164 format)
- **Ensure sufficient Twilio credits**
- **Review Twilio console** for delivery status

### OAuth Issues

- **Verify redirect URIs** match exactly
- **Check app credentials** are correct
- **Ensure OAuth scopes** are properly configured
- **Review OAuth provider logs**

## 8. Development vs Production

### Development

- Use mock services when possible
- Log verification codes to console
- Use localhost URLs for testing

### Production

- Use real email/SMS services
- Implement proper error handling
- Use production URLs and domains
- Enable comprehensive logging

## 9. Next Steps

1. **Complete OAuth implementation** with proper token exchange
2. **Add verification analytics** and reporting
3. **Implement advanced anti-fraud** measures
4. **Add verification reminders** and notifications
5. **Create admin verification** management interface

## Support

For issues with verification services:

1. Check server logs for detailed error messages
2. Verify environment variables are set correctly
3. Test individual services independently
4. Review service provider documentation
5. Check network connectivity and firewall settings
