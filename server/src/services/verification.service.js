const crypto = require('crypto');
const { Resend } = require('resend');
const twilio = require('twilio');

class VerificationService {
    constructor() {
        // Email configuration
        this.resend = null;
        this.setupEmailService();

        // Twilio client for SMS
        this.twilioClient = null;
        this.setupTwilioClient();
    }

    setupEmailService() {
        if (process.env.RESEND_API_KEY) {
            try {
                this.resend = new Resend(process.env.RESEND_API_KEY);
                console.log('✅ Email service configured with Resend');
            } catch (error) {
                console.warn('⚠️  Invalid Resend API key. Email verification will be mocked.');
                this.resend = null;
            }
        } else {
            console.warn('⚠️  RESEND_API_KEY not configured. Email verification will be mocked.');
            console.log('📧 To enable real email verification, set RESEND_API_KEY and EMAIL_FROM in .env');
        }
    }

    setupTwilioClient() {
        if (process.env.TWILIO_ACCOUNT_SID && 
            process.env.TWILIO_AUTH_TOKEN && 
            process.env.TWILIO_ACCOUNT_SID !== 'your-actual-twilio-sid' &&
            process.env.TWILIO_AUTH_TOKEN !== 'your-actual-twilio-token') {
            try {
                this.twilioClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
                console.log('✅ SMS service configured with Twilio');
            } catch (error) {
                console.warn('⚠️  Invalid Twilio credentials. SMS verification will be mocked.');
                this.twilioClient = null;
            }
        } else {
            console.warn('⚠️  Twilio credentials not configured. SMS verification will be mocked.');
            console.log('📱 To enable real SMS verification, set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_PHONE_NUMBER in .env');
        }
    }

    /**
     * Generate email verification token
     */
    generateEmailVerificationToken() {
        return crypto.randomBytes(32).toString('hex');
    }

    /**
     * Generate phone verification code (6 digits)
     */
    generatePhoneVerificationCode() {
        return Math.floor(100000 + Math.random() * 900000).toString();
    }

    /**
     * Send email verification
     */
    async sendEmailVerification(email, fullName, token) {
        try {
            if (this.resend) {
                // Remove trailing slash from FRONTEND_URL to avoid double slashes
                const baseUrl = (process.env.FRONTEND_URL || 'http://localhost:3000').replace(/\/$/, '');
                const verificationUrl = `${baseUrl}/verify-email?token=${token}`;
                const emailFrom = process.env.EMAIL_FROM || 'onboarding@resend.dev';
                
                const { data, error } = await this.resend.emails.send({
                    from: emailFrom,
                    to: email,
                    subject: 'Verify Your JO Service Account',
                    html: `
                        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                            <h2 style="color: #333;">Welcome to JO Service!</h2>
                            <p>Hi ${fullName},</p>
                            <p>Thank you for registering with JO Service. To complete your registration, please verify your email address by clicking the button below:</p>
                            <div style="text-align: center; margin: 30px 0;">
                                <a href="${verificationUrl}" style="background-color: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">Verify Email</a>
                            </div>
                            <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
                            <p style="word-break: break-all; color: #666;">${verificationUrl}</p>
                            <p>This link will expire in 24 hours.</p>
                            <p>If you didn't create this account, please ignore this email.</p>
                            <br>
                            <p>Best regards,<br>The JO Service Team</p>
                        </div>
                    `
                });

                if (error) {
                    console.error('❌ Resend API error:', error);
                    return false;
                }

                console.log('📧 Email verification sent via Resend:', data.id);
                return true;
            } else {
                // Mock email for development
                const baseUrl = (process.env.FRONTEND_URL || 'http://localhost:3000').replace(/\/$/, '');
                console.log('📧 [MOCK] Email verification sent to:', email);
                console.log('📧 [MOCK] Verification token:', token);
                console.log('📧 [MOCK] Verification URL:', `${baseUrl}/verify-email?token=${token}`);
                console.log('📧 [MOCK] In production, this would be sent via Resend');
                return true;
            }
        } catch (error) {
            console.error('❌ Error sending email verification:', error);
            return false;
        }
    }

    /**
     * Send phone verification code via SMS
     * Uses Twilio if configured, otherwise falls back to mock implementation
     */
    async sendPhoneVerificationCode(phoneNumber, code) {
        try {
            if (this.twilioClient && process.env.TWILIO_PHONE_NUMBER) {
                // Send real SMS via Twilio
                const message = await this.twilioClient.messages.create({
                    body: `Your JO Service verification code is: ${code}. This code expires in 10 minutes.`,
                    from: process.env.TWILIO_PHONE_NUMBER,
                    to: phoneNumber
                });
                
                console.log(`📱 SMS sent via Twilio to ${phoneNumber}: ${message.sid}`);
                return true;
            } else {
                // Mock SMS for development/testing
                console.log(`📱 [MOCK] SMS Verification Code for ${phoneNumber}: ${code}`);
                console.log(`📱 [MOCK] In production, this would be sent via Twilio`);
                console.log(`📱 [MOCK] To enable real SMS, set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_PHONE_NUMBER in .env`);
                return true;
            }
        } catch (error) {
            console.error('❌ Error sending SMS verification:', error);
            return false;
        }
    }

    /**
     * Verify email token
     */
    verifyEmailToken(token) {
        // In production, you might want to store tokens in Redis with expiration
        // For now, we'll just return true if token exists
        return token && token.length === 64;
    }

    /**
     * Verify phone code
     */
    verifyPhoneCode(code, storedCode, expiresAt) {
        if (!code || !storedCode) return false;
        if (expiresAt && new Date() > expiresAt) return false;
        return code === storedCode;
    }

    /**
     * Generate OAuth state token for security
     */
    generateOAuthStateToken() {
        return crypto.randomBytes(32).toString('hex');
    }

    /**
     * Validate OAuth callback
     */
    validateOAuthCallback(state, storedState) {
        return state === storedState;
    }

    /**
     * Check if user can request verification (rate limiting)
     */
    canRequestVerification(user, type) {
        const now = new Date();
        const cooldownPeriod = 5 * 60 * 1000; // 5 minutes
        const maxAttempts = 3; // Max attempts per cooldown period

        const attempts = user.verificationAttempts?.[type] || 0;
        const lastAttempt = user.lastVerificationAttempt?.[type];

        // Reset attempts if cooldown period has passed
        if (!lastAttempt || (now - lastAttempt) > cooldownPeriod) {
            return { canRequest: true, remainingAttempts: maxAttempts };
        }

        // Check if user has exceeded max attempts
        if (attempts >= maxAttempts) {
            const timeRemaining = Math.ceil((cooldownPeriod - (now - lastAttempt)) / 1000 / 60);
            return { 
                canRequest: false, 
                remainingAttempts: 0, 
                timeRemaining,
                message: `Too many verification attempts. Please wait ${timeRemaining} minutes.`
            };
        }

        return { 
            canRequest: true, 
            remainingAttempts: maxAttempts - attempts 
        };
    }

    /**
     * Update verification attempt count
     */
    updateVerificationAttempts(user, type) {
        const now = new Date();
        
        if (!user.verificationAttempts) {
            user.verificationAttempts = { email: 0, phone: 0 };
        }
        if (!user.lastVerificationAttempt) {
            user.lastVerificationAttempt = { email: null, phone: null };
        }

        // Reset attempts if cooldown period has passed
        const cooldownPeriod = 5 * 60 * 1000; // 5 minutes
        if (!user.lastVerificationAttempt[type] || 
            (now - user.lastVerificationAttempt[type]) > cooldownPeriod) {
            user.verificationAttempts[type] = 1;
        } else {
            user.verificationAttempts[type] += 1;
        }

        user.lastVerificationAttempt[type] = now;
        return user;
    }
}

module.exports = new VerificationService();
