const axios = require('axios');

class OAuthService {

    // Google OAuth
    static async verifyGoogleToken(idToken) {
        try {
            const response = await axios.get(`https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`);
            
            if (response.data && response.data.sub) {
                return {
                    success: true,
                    userData: {
                        id: response.data.sub,
                        email: response.data.email,
                        fullName: response.data.name,
                        photoUrl: response.data.picture
                    }
                };
            } else {
                return {
                    success: false,
                    message: 'Invalid Google token'
                };
            }
        } catch (error) {
            console.error('Google token verification error:', error);
            return {
                success: false,
                message: 'Failed to verify Google token'
            };
        }
    }

    // Verify OAuth token based on provider
    static async verifyOAuthToken(provider, accessToken, idToken) {
        switch (provider) {
            case 'google':
                return await this.verifyGoogleToken(idToken);
            default:
                return {
                    success: false,
                    message: 'Unsupported OAuth provider'
                };
        }
    }
}

module.exports = OAuthService;
