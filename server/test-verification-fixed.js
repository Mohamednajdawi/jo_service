const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

async function testVerificationSystem() {
    console.log('🧪 Testing JO Service Verification System\n');

    try {
        // Test 1: Register a new user
        console.log('1️⃣ Testing User Registration...');
        const userData = {
            email: `test${Date.now()}@example.com`,
            password: 'password123',
            fullName: 'Test User',
            phoneNumber: '+1234567890'
        };

        const registerResponse = await axios.post(`${BASE_URL}/auth/user/register`, userData);
        console.log('✅ User registered successfully');
        console.log('📧 Email verification required:', registerResponse.data.verificationRequired);
        console.log('📱 SMS verification required:', registerResponse.data.smsSent);
        console.log('👤 User ID:', registerResponse.data.user._id);
        console.log('📧 Email verification token:', registerResponse.data.user.emailVerificationToken);
        console.log('📱 Phone verification code: Check server console logs\n');

        // Test 2: Check verification status
        console.log('2️⃣ Testing Verification Status Check...');
        const statusResponse = await axios.get(`${BASE_URL}/auth/user/status/${registerResponse.data.user._id}`);
        console.log('✅ Status check successful');
        console.log('📧 Email verified:', statusResponse.data.isEmailVerified);
        console.log('📱 Phone verified:', statusResponse.data.isPhoneVerified);
        console.log('🔒 Account status:', statusResponse.data.accountStatus, '\n');

        // Test 3: Test OAuth endpoints (should show not configured)
        console.log('3️⃣ Testing OAuth Endpoints...');
        try {
            const googleResponse = await axios.get(`${BASE_URL}/auth/oauth/google/initiate`);
            console.log('✅ Google OAuth initiated');
        } catch (error) {
            if (error.response?.status === 503) {
                console.log('⚠️  Google OAuth not configured (expected)');
                console.log('📝 Error:', error.response.data.message);
            } else {
                console.log('❌ Unexpected error:', error.message);
            }
        }

        try {
            const facebookResponse = await axios.get(`${BASE_URL}/auth/oauth/facebook/initiate`);
            console.log('✅ Facebook OAuth initiated');
        } catch (error) {
            if (error.response?.status === 503) {
                console.log('⚠️  Facebook OAuth not configured (expected)');
                console.log('📝 Error:', error.response.data.message);
            } else {
                console.log('❌ Unexpected error:', error.message);
            }
        }

        console.log('\n🎉 Verification System Test Complete!');
        console.log('\n📋 Next Steps:');
        console.log('1. Check server console for verification codes');
        console.log('2. Configure real services in .env file');
        console.log('3. Test with real email/SMS services');

    } catch (error) {
        console.error('❌ Test failed:', error.message);
        if (error.response) {
            console.error('Response status:', error.response.status);
            console.error('Response data:', error.response.data);
        }
    }
}

// Run the test
testVerificationSystem();
