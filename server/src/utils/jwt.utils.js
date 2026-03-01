const jwt = require('jsonwebtoken');
require('dotenv').config({ path: require('path').join(__dirname, '..', '..', '.env') }); // To access JWT_SECRET and JWT_EXPIRES_IN

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN;

if (!JWT_SECRET) {
    console.error("FATAL ERROR: JWT_SECRET is not defined.");
    process.exit(1);
}

if (!JWT_EXPIRES_IN) {
    console.warn("Warning: JWT_EXPIRES_IN is not defined. Using default of 1h.");
}

const generateToken = (payload) => {
    // The payload object from auth.controller.js should already contain { id: '...', type: '...' }
    // We add a check here to ensure payload.id and payload.type exist for robustness.
    if (!payload || !payload.id || !payload.type) {
        console.error(
            "JWT Generation Error: generateToken called with invalid payload. 'id' and 'type' are required.", 
            payload
        );
        // Throw an error to catch this during development if an invalid payload is passed.
        throw new Error("Token generation failed: payload must include id and type.");
    }
    return jwt.sign(payload, JWT_SECRET, {
        expiresIn: JWT_EXPIRES_IN || '1h' // Default to 1 hour if not set
    });
};

const verifyToken = (token) => {
    try {
        return jwt.verify(token, JWT_SECRET);
    } catch (error) {
        return null; // Or throw an error, depending on how you want to handle invalid tokens
    }
};

module.exports = {
    generateToken,
    verifyToken,
}; 