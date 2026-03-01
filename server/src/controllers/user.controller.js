const User = require('../models/user.model');
const mongoose = require('mongoose');

const UserController = {
    // GET /api/users/me - Get authenticated user's own profile
    async getMyProfile(req, res) {
        const userId = req.auth.id;
        
        if (!userId) {
            return res.status(400).json({ message: 'User ID not found in authentication token.' });
        }

        if (!mongoose.Types.ObjectId.isValid(userId)) {
            return res.status(400).json({ message: 'Invalid user ID format.' });
        }

        try {
            const user = await User.findById(userId).select('-password');
            
            if (!user) {
                return res.status(404).json({ message: 'User profile not found.' });
            }

            res.status(200).json(user);
        } catch (error) {
            console.error('Error fetching user profile:', error);
            res.status(500).json({ message: 'Failed to fetch user profile', error: error.message });
        }
    },

    // PUT /api/users/me - Update authenticated user's profile
    async updateMyProfile(req, res) {
        const userId = req.auth.id;
        const updateData = req.body;

        // Fields that a user can update (whitelist to prevent unwanted updates)
        const allowedUpdates = [
            'fullName',
            'phoneNumber',
            'profilePictureUrl'
        ];

        const updates = {};
        for (const key of Object.keys(updateData)) {
            if (allowedUpdates.includes(key)) {
                updates[key] = updateData[key];
            }
        }
        
        // Prevent password updates through this route
        if (updates.password) {
            delete updates.password;
        }

        if (Object.keys(updates).length === 0) {
            return res.status(400).json({ message: 'No valid update fields provided.' });
        }

        try {
            const user = await User.findByIdAndUpdate(
                userId,
                { $set: updates },
                { new: true, runValidators: true }
            ).select('-password');

            if (!user) {
                return res.status(404).json({ message: 'User not found.' });
            }

            res.status(200).json({ message: 'Profile updated successfully', user });
        } catch (error) {
            console.error('Error updating user profile:', error);
            if (error.name === 'ValidationError') {
                return res.status(400).json({ message: 'Validation failed', errors: error.errors });
            }
            res.status(500).json({ message: 'Failed to update profile', error: error.message });
        }
    },

    // POST /api/users/me/profile-picture - Upload profile picture
    async uploadProfilePicture(req, res) {
        const userId = req.auth.id;

        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }

        try {
            // Generate the URL for the uploaded file
            const baseUrl = `${req.protocol}://${req.get('host')}`;
            const fileUrl = `${baseUrl}/uploads/profile-pictures/${req.file.filename}`;

            // Update the user's profile with the new picture URL
            const user = await User.findByIdAndUpdate(
                userId,
                { $set: { profilePictureUrl: fileUrl } },
                { new: true, runValidators: true }
            ).select('-password');

            if (!user) {
                return res.status(404).json({ message: 'User not found.' });
            }

            res.status(200).json({ 
                message: 'Profile picture uploaded successfully', 
                profilePictureUrl: fileUrl,
                user 
            });
        } catch (error) {
            console.error('Error uploading profile picture:', error);
            res.status(500).json({ message: 'Failed to upload profile picture', error: error.message });
        }
    },

    // DELETE /api/users/me - Delete authenticated user's account
    async deleteMyAccount(req, res) {
        const userId = req.auth.id;
        
        if (!userId) {
            return res.status(400).json({ message: 'User ID not found in authentication token.' });
        }

        if (!mongoose.Types.ObjectId.isValid(userId)) {
            return res.status(400).json({ message: 'Invalid user ID format.' });
        }

        try {
            // Find the user first to make sure they exist
            const user = await User.findById(userId);
            
            if (!user) {
                return res.status(404).json({ message: 'User not found.' });
            }

            // Delete the user account
            await User.findByIdAndDelete(userId);
            
            // TODO: In a production environment, you might want to:
            // 1. Delete related data (bookings, messages, etc.)
            // 2. Send confirmation email
            // 3. Log the deletion for audit purposes
            // 4. Handle file cleanup (profile pictures, etc.)
            
            res.status(200).json({ 
                message: 'Account deleted successfully',
                success: true 
            });
        } catch (error) {
            console.error('Error deleting user account:', error);
            res.status(500).json({ 
                message: 'Failed to delete account', 
                error: error.message 
            });
        }
    }
};

module.exports = UserController; 