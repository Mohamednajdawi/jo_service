const User = require('../models/user.model');
const Provider = require('../models/provider.model');
const { generateToken } = require('../utils/jwt.utils');
const VerificationService = require('../services/verification.service');
const OAuthService = require('../services/oauth.service');

// Helper function to safely extract user/provider data for response
const getUserResponse = (user) => {
    if (!user) return null;
    return {
        _id: user._id,
        email: user.email,
        fullName: user.fullName,
        phoneNumber: user.phoneNumber,
        profilePictureUrl: user.profilePictureUrl,
        isEmailVerified: user.isEmailVerified,
        isPhoneVerified: user.isPhoneVerified,
        accountStatus: user.accountStatus,
        oauthProvider: user.oauthProvider,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
    };
};

// Helper function to safely extract provider data for response
const getProviderResponse = (provider) => {
    if (!provider) return null;
    // Exclude password and potentially other sensitive fields if needed
    const { password, ...response } = provider.toObject(); // Use .toObject() for clean object
    return response;
};

const AuthController = {
    async registerUser(req, res) {
        const { email, password, fullName, phoneNumber, profilePictureUrl } = req.body;
        try {
            const existingUser = await User.findOne({ email: email.toLowerCase() });
            if (existingUser) {
                return res.status(400).json({ message: 'User already exists with this email' });
            }

            // Generate verification tokens
            const emailVerificationToken = VerificationService.generateEmailVerificationToken();
            const phoneVerificationCode = VerificationService.generatePhoneVerificationCode();
            const phoneVerificationExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

            const newUser = new User({
                email,
                password,
                fullName,
                phoneNumber,
                profilePictureUrl,
                emailVerificationToken,
                phoneVerificationCode,
                phoneVerificationExpires,
                accountStatus: 'pending' // Account starts as pending until verified
            });

            const savedUser = await newUser.save();

            // Send verification emails/SMS
            const emailSent = await VerificationService.sendEmailVerification(email, fullName, emailVerificationToken);
            const smsSent = phoneNumber ? await VerificationService.sendPhoneVerificationCode(phoneNumber, phoneVerificationCode) : true;

            const userResponse = getUserResponse(savedUser);
            
            res.status(201).json({ 
                message: 'User registered successfully. Please verify your email and phone number to activate your account.', 
                user: userResponse,
                verificationRequired: true,
                emailSent,
                smsSent: !!phoneNumber
            });
        } catch (error) {
            console.error('User registration error:', error);
            if (error.name === 'ValidationError') {
                const messages = Object.values(error.errors).map(val => val.message);
                return res.status(400).json({ message: 'Validation Error', errors: messages });
            }
             // Handle duplicate key error (code 11000 for MongoDB)
            if (error.code === 11000) {
                 return res.status(400).json({ message: 'Email already exists.' });
            }
            res.status(500).json({ message: 'Error registering user', error: error.message });
        }
    },

    async loginUser(req, res) {
        const { email, password } = req.body;
        try {
            const user = await User.findOne({ email: email.toLowerCase() }).select('+password');
            if (!user || !(await user.comparePassword(password))) {
                return res.status(401).json({ message: 'Invalid credentials' });
            }

            // Check if account is active
            if (user.accountStatus === 'suspended') {
                return res.status(403).json({ message: 'Account has been suspended. Please contact support.' });
            }

            // Check verification status - Allow login with just email verification for now
            if (!user.isEmailVerified) {
                return res.status(403).json({ 
                    message: 'Email not verified. Please verify your email address.',
                    verificationRequired: true,
                    isEmailVerified: false,
                    isPhoneVerified: user.isPhoneVerified
                });
            }
            
            // Phone verification is optional for now
            if (!user.isPhoneVerified) {
                console.log(`User ${user.email} logged in with email verified but phone not verified`);
            }

            const userResponse = getUserResponse(user);
            const token = generateToken({ id: user._id, type: 'user' });
            res.status(200).json({ message: 'User logged in successfully', user: userResponse, token });
        } catch (error) {
            console.error('User login error:', error);
            res.status(500).json({ message: 'Error logging in user', error: error.message });
        }
    },

    // --- User Verification ---

    async verifyEmail(req, res) {
        const { token } = req.params;
        try {
            const user = await User.findOne({ emailVerificationToken: token });
            if (!user) {
                return res.status(400).json({ message: 'Invalid or expired verification token' });
            }

            user.isEmailVerified = true;
            user.emailVerificationToken = null;
            
            // Activate account when email is verified
            if (user.accountStatus === 'pending') {
                user.accountStatus = 'active';
            }
            
            await user.save();

            res.status(200).json({ 
                message: 'Email verified successfully',
                isEmailVerified: true,
                isPhoneVerified: user.isPhoneVerified
            });
        } catch (error) {
            console.error('Email verification error:', error);
            res.status(500).json({ message: 'Error verifying email', error: error.message });
        }
    },

    async verifyPhone(req, res) {
        const { code, email } = req.body;
        try {
            // Find user by email instead of requiring authentication
            const user = await User.findOne({ email: email.toLowerCase() });
            if (!user) {
                return res.status(404).json({ message: 'User not found' });
            }

            if (!user.phoneVerificationCode || !user.phoneVerificationExpires) {
                return res.status(400).json({ message: 'No verification code found' });
            }

            if (new Date() > user.phoneVerificationExpires) {
                return res.status(400).json({ message: 'Verification code has expired' });
            }

            if (code !== user.phoneVerificationCode) {
                return res.status(400).json({ message: 'Invalid verification code' });
            }

            user.isPhoneVerified = true;
            user.phoneVerificationCode = null;
            user.phoneVerificationExpires = null;

            // Activate account when email is verified (phone verification optional for now)
            if (user.isEmailVerified) {
                user.accountStatus = 'active';
            }

            await user.save();

            res.status(200).json({ 
                message: 'Phone number verified successfully',
                isEmailVerified: user.isEmailVerified,
                isPhoneVerified: true,
                accountStatus: user.accountStatus
            });
        } catch (error) {
            console.error('Phone verification error:', error);
            res.status(500).json({ message: 'Error verifying phone', error: error.message });
        }
    },

    async resendVerificationCode(req, res) {
        const { email } = req.body;
        try {
            if (!email) {
                return res.status(400).json({ message: 'Email is required' });
            }

            const user = await User.findOne({ email: email.toLowerCase() });
            if (!user) {
                return res.status(404).json({ message: 'User not found' });
            }

            if (user.isPhoneVerified) {
                return res.status(400).json({ message: 'Phone number is already verified' });
            }

            // Check rate limiting
            const rateLimitCheck = VerificationService.canRequestVerification(user, 'phone');
            if (!rateLimitCheck.canRequest) {
                return res.status(429).json({ 
                    message: rateLimitCheck.message,
                    timeRemaining: rateLimitCheck.timeRemaining
                });
            }

            // Generate new verification code
            const phoneVerificationCode = VerificationService.generatePhoneVerificationCode();
            const phoneVerificationExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

            user.phoneVerificationCode = phoneVerificationCode;
            user.phoneVerificationExpires = phoneVerificationExpires;
            
            // Update rate limiting
            VerificationService.updateVerificationAttempts(user, 'phone');
            
            await user.save();

            // Send new SMS
            const smsSent = await VerificationService.sendPhoneVerificationCode(user.phoneNumber, phoneVerificationCode);

            res.status(200).json({ 
                message: 'Verification code resent successfully',
                smsSent,
                remainingAttempts: rateLimitCheck.remainingAttempts - 1
            });
        } catch (error) {
            console.error('Resend verification error:', error);
            res.status(500).json({ message: 'Error resending verification code', error: error.message });
        }
    },

    async resendEmailVerification(req, res) {
        const { email } = req.body;
        try {
            const user = await User.findOne({ email: email.toLowerCase() });
            if (!user) {
                return res.status(404).json({ message: 'User not found' });
            }

            if (user.isEmailVerified) {
                return res.status(400).json({ message: 'Email is already verified' });
            }

            // Check rate limiting
            const rateLimitCheck = VerificationService.canRequestVerification(user, 'email');
            if (!rateLimitCheck.canRequest) {
                return res.status(429).json({ 
                    message: rateLimitCheck.message,
                    timeRemaining: rateLimitCheck.timeRemaining
                });
            }

            // Generate new email verification token
            const emailVerificationToken = VerificationService.generateEmailVerificationToken();
            user.emailVerificationToken = emailVerificationToken;
            
            // Update rate limiting
            VerificationService.updateVerificationAttempts(user, 'email');
            
            await user.save();

            // Send new verification email
            const emailSent = await VerificationService.sendEmailVerification(user.email, user.fullName, emailVerificationToken);

            if (emailSent) {
                res.status(200).json({ 
                    message: 'Verification email resent successfully',
                    emailSent: true,
                    remainingAttempts: rateLimitCheck.remainingAttempts - 1
                });
            } else {
                res.status(500).json({ message: 'Failed to send verification email' });
            }
        } catch (error) {
            console.error('Resend email verification error:', error);
            res.status(500).json({ message: 'Error resending verification email', error: error.message });
        }
    },

    async getUserVerificationStatus(req, res) {
        const { userId } = req.params;
        try {
            const user = await User.findById(userId).select('isEmailVerified isPhoneVerified accountStatus');
            if (!user) {
                return res.status(404).json({ message: 'User not found' });
            }

            res.status(200).json({
                isEmailVerified: user.isEmailVerified,
                isPhoneVerified: user.isPhoneVerified,
                accountStatus: user.accountStatus
            });
        } catch (error) {
            console.error('Get user verification status error:', error);
            res.status(500).json({ message: 'Error getting user verification status', error: error.message });
        }
    },

    async getUserByEmail(req, res) {
        const { email } = req.body;
        try {
            if (!email) {
                return res.status(400).json({ message: 'Email is required' });
            }

            const user = await User.findOne({ email: email.toLowerCase() }).select('isEmailVerified isPhoneVerified accountStatus');
            if (!user) {
                return res.status(404).json({ message: 'User not found' });
            }

            res.status(200).json({
                isEmailVerified: user.isEmailVerified,
                isPhoneVerified: user.isPhoneVerified,
                accountStatus: user.accountStatus
            });
        } catch (error) {
            console.error('Get user by email error:', error);
            res.status(500).json({ message: 'Error getting user by email', error: error.message });
        }
    },

    // --- OAuth Integration ---

    async initiateOAuth(req, res) {
        const { provider } = req.params; // 'facebook' or 'google'
        try {
            if (!['facebook', 'google'].includes(provider)) {
                return res.status(400).json({ message: 'Invalid OAuth provider' });
            }

            // Check if OAuth is configured
            if (provider === 'facebook' && (!process.env.FACEBOOK_APP_ID || !process.env.FACEBOOK_APP_SECRET)) {
                return res.status(503).json({ 
                    message: 'Facebook OAuth is not configured',
                    error: 'FACEBOOK_APP_ID and FACEBOOK_APP_SECRET are required in .env file',
                    setupRequired: true
                });
            }

            if (provider === 'google' && !process.env.GOOGLE_CLIENT_ID) {
                return res.status(503).json({ 
                    message: 'Google OAuth is not configured',
                    error: 'GOOGLE_CLIENT_ID is required in .env file',
                    setupRequired: true
                });
            }

            const stateToken = VerificationService.generateOAuthStateToken();
            
            // Store state token in session or temporary storage
            // For now, we'll return it (in production, store in Redis)
            
            let authUrl;
            if (provider === 'facebook') {
                authUrl = `https://www.facebook.com/v12.0/dialog/oauth?client_id=${process.env.FACEBOOK_APP_ID}&redirect_uri=${process.env.FACEBOOK_REDIRECT_URI}&state=${stateToken}&scope=email,public_profile`;
            } else if (provider === 'google') {
                authUrl = `https://accounts.google.com/o/oauth2/v2/auth?client_id=${process.env.GOOGLE_CLIENT_ID}&redirect_uri=${process.env.GOOGLE_REDIRECT_URI}&response_type=code&scope=email profile&state=${stateToken}`;
            }

            res.status(200).json({ 
                message: 'OAuth initiated successfully',
                authUrl,
                stateToken
            });
        } catch (error) {
            console.error('OAuth initiation error:', error);
            res.status(500).json({ message: 'Error initiating OAuth', error: error.message });
        }
    },

    async oauthCallback(req, res) {
        const { provider } = req.params;
        const { accessToken, idToken, userData } = req.body;
        
        try {
            if (!['facebook', 'google'].includes(provider)) {
                return res.status(400).json({ message: 'Invalid OAuth provider' });
            }

            // Check if OAuth is configured
            if (provider === 'facebook' && (!process.env.FACEBOOK_APP_ID || !process.env.FACEBOOK_APP_SECRET)) {
                return res.status(503).json({ 
                    message: 'Facebook OAuth is not configured',
                    error: 'FACEBOOK_APP_ID and FACEBOOK_APP_SECRET are required in .env file',
                    setupRequired: true
                });
            }

            if (provider === 'google' && !process.env.GOOGLE_CLIENT_ID) {
                return res.status(503).json({ 
                    message: 'Google OAuth is not configured',
                    error: 'GOOGLE_CLIENT_ID is required in .env file',
                    setupRequired: true
                });
            }

            // Verify OAuth token with the provider
            const verificationResult = await OAuthService.verifyOAuthToken(provider, accessToken, idToken);
            
            if (!verificationResult.success) {
                return res.status(400).json({ message: verificationResult.message });
            }

            // Extract user information from verified OAuth data
            const verifiedUserData = verificationResult.userData;
            const email = verifiedUserData.email;
            const fullName = verifiedUserData.fullName;
            const profilePictureUrl = verifiedUserData.picture?.data?.url || verifiedUserData.photoUrl;

            if (!email) {
                return res.status(400).json({ message: 'Email is required from OAuth provider' });
            }

            // Check if user already exists
            let user = await User.findOne({ email: email.toLowerCase() });
            
            if (!user) {
                // Create new user from OAuth
                user = new User({
                    email: email.toLowerCase(),
                    fullName: fullName || 'OAuth User',
                    profilePictureUrl,
                    oauthProvider: provider,
                    isEmailVerified: true, // OAuth users are pre-verified
                    isPhoneVerified: false, // Phone verification still required
                    accountStatus: 'pending', // Pending phone verification
                    password: null, // No password for OAuth users
                });

                await user.save();
            } else {
                // Update existing user's OAuth information
                user.oauthProvider = provider;
                if (profilePictureUrl) {
                    user.profilePictureUrl = profilePictureUrl;
                }
                if (fullName && !user.fullName) {
                    user.fullName = fullName;
                }
                await user.save();
            }

            // Generate JWT token
            const token = generateToken({ id: user._id, type: 'user' });

            // Return user data and token
            const userResponse = getUserResponse(user);
            res.status(200).json({
                message: `${provider.charAt(0).toUpperCase() + provider.slice(1)} login successful`,
                user: userResponse,
                token,
                oauthProvider: provider
            });

        } catch (error) {
            console.error('OAuth callback error:', error);
            res.status(500).json({ message: 'Error processing OAuth login', error: error.message });
        }
    },

    // --- Provider Auth --- 

    async registerProvider(req, res) {
        const {
            email, password, fullName, serviceType, hourlyRate,
            locationLatitude, locationLongitude, addressText, city, // Added city parameter
            availabilityDetails, serviceDescription, profilePictureUrl
        } = req.body;

        try {
            const existingProvider = await Provider.findOne({ email: email.toLowerCase() });
            if (existingProvider) {
                return res.status(400).json({ message: 'Provider already exists with this email' });
            }

            // Construct location object
            let location = {};
            if (locationLongitude != null && locationLatitude != null) { // Use != null to allow 0
                location.point = {
                    type: 'Point',
                    coordinates: [parseFloat(locationLongitude), parseFloat(locationLatitude)]
                };
            }
            if (addressText) {
                location.addressText = addressText;
            }
            if (city) {
                location.city = city;
                
                // Add city to service areas array if it's not already there
                const serviceAreas = [city];
                
                const newProvider = new Provider({
                    email,
                    password,
                    fullName,
                    serviceType,
                    hourlyRate,
                    location: Object.keys(location).length > 0 ? location : undefined,
                    serviceAreas, // Add service areas
                    availabilityDetails,
                    serviceDescription,
                    profilePictureUrl
                });
                
                const savedProvider = await newProvider.save();
                const providerResponse = getProviderResponse(savedProvider);
                const token = generateToken({ id: savedProvider._id, type: 'provider' });
                
                res.status(201).json({ 
                    message: 'Provider registered successfully', 
                    provider: providerResponse, 
                    token 
                });
            } else {
                // If no city is provided, continue without service areas
                const newProvider = new Provider({
                    email,
                    password,
                    fullName,
                    serviceType,
                    hourlyRate,
                    location: Object.keys(location).length > 0 ? location : undefined,
                    availabilityDetails,
                    serviceDescription,
                    profilePictureUrl
                });
                
                const savedProvider = await newProvider.save();
                const providerResponse = getProviderResponse(savedProvider);
                const token = generateToken({ id: savedProvider._id, type: 'provider' });
                
                res.status(201).json({ 
                    message: 'Provider registered successfully', 
                    provider: providerResponse, 
                    token 
                });
            }
        } catch (error) {
            console.error('Provider registration error:', error);
            if (error.name === 'ValidationError') {
                const messages = Object.values(error.errors).map(val => val.message);
                return res.status(400).json({ message: 'Validation Error', errors: messages });
            }
             // Handle duplicate key error
            if (error.code === 11000) {
                 return res.status(400).json({ message: 'Email already exists.' });
            }
            res.status(500).json({ message: 'Error registering provider', error: error.message });
        }
    },

    async loginProvider(req, res) {
        const { email, password } = req.body;
        try {
            // Need to explicitly select password as it's excluded by default in the schema
            const provider = await Provider.findOne({ email: email.toLowerCase() }).select('+password');
            
            // Check if provider exists and password matches
            if (!provider || !(await provider.comparePassword(password))) {
                return res.status(401).json({ message: 'Invalid credentials' });
            }

            // Prepare response object (excluding password)
            const providerResponse = getProviderResponse(provider);
            const token = generateToken({ id: provider._id, type: 'provider' });
            
            res.status(200).json({ 
                message: 'Provider logged in successfully', 
                provider: providerResponse, 
                token 
            });
        } catch (error) {
            console.error('Provider login error:', error);
            res.status(500).json({ message: 'Error logging in provider', error: error.message });
        }
    }
};

module.exports = AuthController; 