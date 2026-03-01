const { verifyToken } = require('../utils/jwt.utils');

const protectRoute = (req, res, next) => {
    let token;
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            token = req.headers.authorization.split(' ')[1];
            const decoded = verifyToken(token);

            if (!decoded) {
                return res.status(401).json({ message: 'Not authorized, token failed' });
            }

            // Attach user/provider info to request object
            // The payload from generateToken included { id: userIdOrProviderId, type: userType }
            req.auth = decoded; // Contains id (user_id or provider_id) and type ('user' or 'provider')
            next();
        } catch (error) {
            console.error('Token verification error:', error);
            return res.status(401).json({ message: 'Not authorized, token failed' });
        }
    } else {
        return res.status(401).json({ message: 'Not authorized, no token' });
    }
};

// Middleware to check if the authenticated entity is a regular user
const isUser = (req, res, next) => {
    if (req.auth && req.auth.type === 'user') {
        next();
    } else {
        return res.status(403).json({ message: 'Forbidden: User access required' });
    }
};

// Middleware to check if the authenticated entity is a service provider
const isProvider = (req, res, next) => {
    if (req.auth && req.auth.type === 'provider') {
        next();
    } else {
        return res.status(403).json({ message: 'Forbidden: Provider access required' });
    }
};

// Middleware to check for admin role
const isAdmin = (req, res, next) => {
    if (req.auth && req.auth.role === 'admin') {
        next();
    } else {
        return res.status(403).json({ message: 'Forbidden: Admin access required' });
    }
};

module.exports = {
    protectRoute, // General token protection
    isUser,       // Role check for user
    isProvider,   // Role check for provider
    isAdmin,      // Role check for admin (to be expanded)
}; 