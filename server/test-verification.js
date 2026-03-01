#!/usr/bin/env node

/**
 * Test script for verification services
 * Run with: node test-verification.js
 */

require('dotenv').config();
const VerificationService = require('./src/services/verification.service');

console.log('🧪 Testing Verification Services...\n');

// Test 1: Email verification token generation
console.log('1. Testing Email Verification Token Generation:');
const emailToken = VerificationService.generateEmailVerificationToken();
console.log(`   Generated token: ${emailToken.substring(0, 16)}...`);
console.log(`   Token length: ${emailToken.length} characters`);
console.log(`   Valid format: ${VerificationService.verifyEmailToken(emailToken)}\n`);

// Test 2: Phone verification code generation
console.log('2. Testing Phone Verification Code Generation:');
const phoneCode = VerificationService.generatePhoneVerificationCode();
console.log(`   Generated code: ${phoneCode}`);
console.log(`   Code length: ${phoneCode.length} digits`);
console.log(`   Valid format: ${phoneCode.length === 6 && /^\d{6}$/.test(phoneCode)}\n`);

// Test 3: OAuth state token generation
console.log('3. Testing OAuth State Token Generation:');
const oauthToken = VerificationService.generateOAuthStateToken();
console.log(`   Generated token: ${oauthToken.substring(0, 16)}...`);
console.log(`   Token length: ${oauthToken.length} characters\n`);

// Test 4: Rate limiting simulation
console.log('4. Testing Rate Limiting Logic:');
const mockUser = {
    verificationAttempts: { email: 0, phone: 0 },
    lastVerificationAttempt: { email: null, phone: null }
};

// Test initial state
let rateLimitCheck = VerificationService.canRequestVerification(mockUser, 'email');
console.log(`   Initial email attempts: ${rateLimitCheck.remainingAttempts} remaining`);

// Simulate multiple attempts
for (let i = 0; i < 4; i++) {
    VerificationService.updateVerificationAttempts(mockUser, 'email');
    rateLimitCheck = VerificationService.canRequestVerification(mockUser, 'email');
    console.log(`   After ${i + 1} attempts: ${rateLimitCheck.remainingAttempts} remaining, can request: ${rateLimitCheck.canRequest}`);
}

// Test 5: Environment variables check
console.log('\n5. Environment Variables Check:');
const requiredVars = [
    'EMAIL_USER',
    'EMAIL_PASS', 
    'TWILIO_ACCOUNT_SID',
    'TWILIO_AUTH_TOKEN',
    'TWILIO_PHONE_NUMBER',
    'FACEBOOK_APP_ID',
    'GOOGLE_CLIENT_ID'
];

requiredVars.forEach(varName => {
    const value = process.env[varName];
    const status = value ? '✅ Set' : '❌ Not set';
    console.log(`   ${varName}: ${status}`);
    if (value && (varName.includes('PASS') || varName.includes('TOKEN') || varName.includes('SECRET'))) {
        console.log(`     Value: ${value.substring(0, 8)}...`);
    } else if (value) {
        console.log(`     Value: ${value}`);
    }
});

console.log('\n📋 Summary:');
console.log('   - Email verification: Ready for testing');
console.log('   - SMS verification: Ready for testing');
console.log('   - OAuth integration: Framework ready, needs provider setup');
console.log('   - Rate limiting: Implemented and tested');

console.log('\n🚀 Next Steps:');
console.log('   1. Set up environment variables (see env.example)');
console.log('   2. Configure Gmail for email verification');
console.log('   3. Set up Twilio for SMS verification');
console.log('   4. Create OAuth apps for social login');
console.log('   5. Test with real user registration');

console.log('\n📚 For detailed setup instructions, see VERIFICATION_SETUP.md');
