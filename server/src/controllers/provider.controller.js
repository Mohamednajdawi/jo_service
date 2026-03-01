const Provider = require('../models/provider.model');
const mongoose = require('mongoose');

const ProviderController = {

    // GET /api/providers - Get list of providers with filtering and pagination
    async getAllProviders(req, res) {
        const { serviceType, page = 1, limit = 10, // Basic filters
                minRating, onlyAvailable, // Optional filters
                // Geospatial filter params (example)
                longitude, latitude, maxDistance // distance in meters
              } = req.query;
        
        try {
            const query = {};
            const options = {
                page: parseInt(page, 10),
                limit: parseInt(limit, 10),
                sort: { averageRating: -1, totalRatings: -1 }, // Sort by rating, then number of ratings
                // Exclude sensitive fields like password (already excluded by select: false in schema)
                select: '-password' // Double ensure password isn't selected
                // We can add .populate() here later if needed (e.g., recent reviews)
            };

            // Only show verified providers to users
            query.verificationStatus = 'verified';
            
            console.log('🔍 getAllProviders query:', JSON.stringify(query, null, 2));

            // Apply Filters
            if (serviceType) {
                // Case-insensitive search for service type
                query.serviceType = { $regex: new RegExp(`^${serviceType}$`, 'i') };
            }
            if (minRating) {
                const rating = parseFloat(minRating);
                if (!isNaN(rating)) {
                    query.averageRating = { $gte: rating };
                }
            }

            // Geospatial Filter (if coordinates provided)
            if (longitude != null && latitude != null) {
                const lon = parseFloat(longitude);
                const lat = parseFloat(latitude);
                const dist = maxDistance ? parseFloat(maxDistance) : 10000; // Default 10km

                if (!isNaN(lon) && !isNaN(lat)) {
                    query['location.point'] = {
                        $nearSphere: {
                            $geometry: {
                                type: "Point",
                                coordinates: [lon, lat]
                            },
                            $maxDistance: dist // in meters
                        }
                    };
                    // Note: Sorting by distance might override the rating sort.
                    // If sorting by distance is desired, adjust the `sort` option or handle separately.
                }
            }

            // Filter by availability
            if (onlyAvailable === 'true') {
                query.isAvailable = true;
            }

            // Query using pagination (manual approach shown, mongoose-paginate-v2 is an alternative)
            const skip = (options.page - 1) * options.limit;
            const providers = await Provider.find(query)
                                      .sort(options.sort)
                                      .select(options.select)
                                      .skip(skip)
                                      .limit(options.limit);

            const totalProviders = await Provider.countDocuments(query);
            
            console.log(`🔍 getAllProviders results: ${providers.length} providers found, total: ${totalProviders}`);
            
            res.status(200).json({
                providers,
                currentPage: options.page,
                totalPages: Math.ceil(totalProviders / options.limit),
                totalProviders
            });

        } catch (error) {
            console.error('Error fetching providers:', error);
            res.status(500).json({ message: 'Failed to fetch providers', error: error.message });
        }
    },

    // GET /api/providers/:id - Get a single provider's public profile
    async getProviderById(req, res) {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid Provider ID format' });
        }

        try {
            // Only show verified providers to users
            const provider = await Provider.findOne({
                _id: id,
                verificationStatus: 'verified'
            }).select('-password'); 
            
            if (!provider) {
                return res.status(404).json({ message: 'Provider not found.' });
            }

            // Return public profile data
            res.status(200).json(provider);

        } catch (error) {
            console.error('Error fetching provider by ID:', error);
            res.status(500).json({ message: 'Failed to fetch provider profile', error: error.message });
        }
    },

    // PUT /api/providers/me - Update authenticated provider's profile
    async updateMyProfile(req, res) {
        const providerId = req.auth.id; // Corrected from req.user.id to req.auth.id
        const updateData = req.body;

        // Fields that a provider can update (whitelist to prevent unwanted updates)
        const allowedUpdates = [
            'fullName',
            'phoneNumber', // ✅ FIXED: Added phoneNumber to allowed updates
            'businessName', // ✅ FIXED: Changed from 'companyName' to match schema
            'serviceType', 
            'serviceDescription',
            'serviceCategory',
            'serviceTags',
            'serviceAreas',
            'profilePictureUrl',
            'hourlyRate',
            'availability',
            'isAvailable', // ✅ ADDED: Allow updating availability status
            // Location and address will be handled separately below
        ];

        const updates = {};
        
        // Handle regular field updates
        for (const key of Object.keys(updateData)) {
            if (allowedUpdates.includes(key)) {
                // Ensure hourlyRate is stored as a number if provided
                if (key === 'hourlyRate') {
                    const rate = parseFloat(updateData[key]);
                    if (!isNaN(rate) && rate >= 0) {
                        updates[key] = rate;
                    }
                } else {
                    updates[key] = updateData[key];
                }
            }
        }
        
        // ✅ FIXED: Handle address updates more flexibly
        // Support both simple address string and complex location object
        if (updateData.address || updateData.location) {
            const currentProvider = await Provider.findById(providerId);
            if (!currentProvider) {
                return res.status(404).json({ message: 'Provider not found.' });
            }

            // Initialize location object with existing data or defaults
            const locationUpdate = {
                type: 'Point',
                coordinates: currentProvider.location?.coordinates || [0, 0],
                address: currentProvider.location?.address || '',
                city: currentProvider.location?.city || '',
                state: currentProvider.location?.state || '',
                zipCode: currentProvider.location?.zipCode || '',
                country: currentProvider.location?.country || 'US'
            };

            // Handle simple address string update
            if (updateData.address && typeof updateData.address === 'string') {
                locationUpdate.address = updateData.address.trim();
            }

            // Handle complex location object update
            if (updateData.location) {
                if (updateData.location.address) {
                    locationUpdate.address = updateData.location.address.trim();
                }
                if (updateData.location.city) {
                    locationUpdate.city = updateData.location.city.trim();
                }
                if (updateData.location.state) {
                    locationUpdate.state = updateData.location.state.trim();
                }
                if (updateData.location.zipCode) {
                    locationUpdate.zipCode = updateData.location.zipCode.trim();
                }
                if (updateData.location.country) {
                    locationUpdate.country = updateData.location.country.trim();
                }
                
                // Handle coordinates if provided
                if (Array.isArray(updateData.location.coordinates) && 
                    updateData.location.coordinates.length === 2 &&
                    typeof updateData.location.coordinates[0] === 'number' &&
                    typeof updateData.location.coordinates[1] === 'number'
                ) {
                    locationUpdate.coordinates = [updateData.location.coordinates[0], updateData.location.coordinates[1]];
                } else if (updateData.location.coordinates) {
                    return res.status(400).json({ message: "Invalid location.coordinates format. Expected [longitude, latitude]." });
                }
            }

            updates.location = locationUpdate;
        }
        
        // Prevent password updates through this route
        if (updates.password) {
            delete updates.password;
        }

        // Check if we have any updates to make
        if (Object.keys(updates).length === 0) {
            return res.status(400).json({ message: 'No valid update fields provided.' });
        }
        
        console.log('📝 Updating provider profile with data:', JSON.stringify(updates, null, 2));

        try {
            const provider = await Provider.findByIdAndUpdate(
                providerId,
                { $set: updates },
                { new: true, runValidators: true, context: 'query' }
            ).select('-password');

            if (!provider) {
                return res.status(404).json({ message: 'Provider not found.' });
            }

            console.log('✅ Provider profile updated successfully');
            res.status(200).json({ message: 'Profile updated successfully', provider });
        } catch (error) {
            console.error('❌ Error updating provider profile:', error);
            if (error.name === 'ValidationError') {
                return res.status(400).json({ message: 'Validation failed', errors: error.errors });
            }
            res.status(500).json({ message: 'Failed to update profile', error: error.message });
        }
    },

    // GET /api/providers/me - Get authenticated provider's own profile
    async getMyProfile(req, res) {
        
        const rawProviderId = req.auth.id; // Get the ID from the token
        
        // Check if the token is actually present and formatted correctly
        if (!req.headers.authorization) {
            console.error('[getMyProfile] Error: Missing authorization header');
            return res.status(401).json({ message: 'Missing authorization header' });
        }

        if (!rawProviderId) {
            console.error('[getMyProfile] Error: Provider ID not found in token payload (req.auth.id).');
            return res.status(400).json({ message: 'Provider ID not found in authentication token.' });
        }

        // Ensure it's a valid ObjectId
        
        if (!mongoose.Types.ObjectId.isValid(rawProviderId)) {
            console.error('[getMyProfile] Error: Invalid Provider ID format received from token:', rawProviderId);
            return res.status(400).json({ message: 'Invalid Provider ID format in token.' });
        }

        const providerObjectId = new mongoose.Types.ObjectId(rawProviderId);

        try {
            const provider = await Provider.findById(providerObjectId).select('-password');
            
            if (!provider) {
                console.warn('[getMyProfile] Provider not found in DB for ID:', providerObjectId);
                return res.status(404).json({ message: 'Provider profile not found.' });
            }

            res.status(200).json(provider);
        } catch (error) {
            console.error('[getMyProfile] Error fetching own provider profile for ID:', providerObjectId, 'Error:', error);
            if (error.name === 'CastError') {
                return res.status(400).json({ message: 'Invalid Provider ID format during database query.', details: error.message });
            }
            res.status(500).json({ message: 'Failed to fetch provider profile', error: error.message });
        }
    },

    // POST /api/providers/me/profile-picture - Upload profile picture
    async uploadProfilePicture(req, res) {
        const providerId = req.auth.id;

        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }

        try {
            // Generate the URL for the uploaded file
            const baseUrl = `${req.protocol}://${req.get('host')}`;
            const fileUrl = `${baseUrl}/uploads/profile-pictures/${req.file.filename}`;

            // Update the provider's profile with the new picture URL
            const provider = await Provider.findByIdAndUpdate(
                providerId,
                { $set: { profilePictureUrl: fileUrl } },
                { new: true, runValidators: true }
            ).select('-password');

            if (!provider) {
                return res.status(404).json({ message: 'Provider not found.' });
            }

            res.status(200).json({ 
                message: 'Profile picture uploaded successfully', 
                profilePictureUrl: fileUrl,
                provider 
            });
        } catch (error) {
            console.error('Error uploading profile picture:', error);
            res.status(500).json({ message: 'Failed to upload profile picture', error: error.message });
        }
    },

    // GET /api/providers/search - Search providers with filtering
    async searchProviders(req, res) {
        try {
            const {
                query,             // Text search query
                category,          // Service category
                location,          // Location filter
                minRating,         // Minimum rating
                maxPrice,          // Maximum hourly rate
                maxDistance,       // Maximum distance in km
                onlyAvailable,     // Only show available providers
                tags,              // Comma-separated service tags
                sort = 'rating',   // Sort field (rating, price, distance)
                order = 'desc',    // Sort order (asc, desc)
                page = 1,          // Page number
                limit = 10,        // Results per page
                latitude,          // User's latitude for distance calculation
                longitude,         // User's longitude for distance calculation
            } = req.query;
            
            // Build the query object
            const queryObj = {};
            
            // Only include active and verified providers
            queryObj.accountStatus = 'active';
            queryObj.verificationStatus = 'verified';
            
            console.log('🔍 Search parameters:', {
                query, location, latitude, longitude, maxDistance,
                category, minRating, maxPrice, onlyAvailable
            });
            
            // Apply text search if query is provided
            if (query && query.trim()) {
                // Use text search if available, otherwise use regex
                if (query.length > 2) {
                    queryObj.$or = [
                        { fullName: { $regex: query, $options: 'i' } },
                        { companyName: { $regex: query, $options: 'i' } },
                        { serviceType: { $regex: query, $options: 'i' } },
                        { serviceDescription: { $regex: query, $options: 'i' } }
                    ];
                }
            }
            
            // Filter by category/service type
            if (category && category !== 'All') {
                queryObj.serviceType = { $regex: new RegExp(`^${category}$`, 'i') };
            }
            
            // Filter by location with improved text matching
            if (location && location.trim()) {
                queryObj.$or = queryObj.$or || [];
                
                // Split location into words for more flexible matching
                const locationWords = location.trim().split(/\s+/).filter(word => word.length > 1);
                
                // Create multiple search patterns for better matching
                const searchPatterns = [
                    location, // Exact location string
                    ...locationWords, // Individual words
                    location.replace(/\s+/g, '.*'), // Words with wildcards
                    // Add street name patterns (remove numbers for better matching)
                    ...locationWords.filter(word => !/\d/.test(word)), // Words without numbers
                    location.replace(/\d+/g, '').trim(), // Location without numbers
                ];
                
                // Add patterns for each searchable field
                searchPatterns.forEach(pattern => {
                    if (pattern.length > 1) { // Only add patterns with meaningful length
                        queryObj.$or.push(
                            { 'location.city': { $regex: pattern, $options: 'i' } },
                            { 'location.address': { $regex: pattern, $options: 'i' } },
                            { serviceAreas: { $regex: pattern, $options: 'i' } }
                        );
                    }
                });
                
                console.log(`🔍 Location search patterns: ${searchPatterns.join(', ')}`);
            }
            
            // Filter by minimum rating
            if (minRating && parseFloat(minRating) > 0) {
                queryObj.averageRating = { $gte: parseFloat(minRating) };
            }
            
            // Filter by maximum price
            if (maxPrice && parseFloat(maxPrice) > 0) {
                queryObj.hourlyRate = { $lte: parseFloat(maxPrice) };
            }
            
            // Enable geospatial search when coordinates are provided
            if (latitude && longitude && maxDistance) {
                const lat = parseFloat(latitude);
                const lon = parseFloat(longitude);
                const distance = parseFloat(maxDistance); // Distance in km
                if (!isNaN(lat) && !isNaN(lon) && !isNaN(distance)) {
                    // STRICT DISTANCE SEARCH: Only return providers within the specified distance
                    console.log(`🔍 Strict distance search: Only providers within ${distance}km will be returned`);
                    
                    // For geospatial search, only include providers with valid coordinates
                    // MongoDB requires $nearSphere to be the first condition
                    queryObj['location.coordinates'] = {
                        $nearSphere: {
                            $geometry: {
                                type: 'Point',
                                coordinates: [lon, lat]
                            },
                            $maxDistance: distance * 1000 // Convert km to meters
                        }
                    };
                    
                    // Add additional conditions for valid coordinates
                    queryObj.$and = queryObj.$and || [];
                    queryObj.$and.push({
                        'location.coordinates': {
                            $exists: true,
                            $ne: []
                        }
                    });
                    
                    console.log(`🔍 Geospatial search: lat=${lat}, lon=${lon}, distance=${distance}km (${distance * 1000}m)`);
                    
                    // Execute the geospatial query only - NO TEXT FALLBACK
                    const geoProviders = await Provider.find(queryObj).select('-password');
                    
                    console.log(`🔍 Geospatial results: ${geoProviders.length} providers within ${distance}km`);
                    
                    // Apply pagination to geospatial results only
                    const startIndex = (parseInt(page, 10) - 1) * parseInt(limit, 10);
                    const endIndex = startIndex + parseInt(limit, 10);
                    const paginatedProviders = geoProviders.slice(startIndex, endIndex);
                    
                    res.status(200).json({
                        providers: paginatedProviders,
                        currentPage: parseInt(page, 10),
                        totalPages: Math.ceil(geoProviders.length / parseInt(limit, 10)),
                        totalProviders: geoProviders.length,
                        hasMore: endIndex < geoProviders.length
                    });
                    return;
                }
            }
            
            // Filter by availability
            if (onlyAvailable === 'true') {
                queryObj.isAvailable = true;
            }
            
            // Filter by service tags
            if (tags && tags.trim()) {
                const tagArray = tags.split(',').map(tag => tag.trim()).filter(tag => tag.length > 0);
                if (tagArray.length > 0) {
                    queryObj.serviceTags = { $in: tagArray };
                }
            }
            
            // Set up sorting
            let sortObj = {};
            if (sort === 'rating') {
                sortObj.averageRating = order === 'asc' ? 1 : -1;
                sortObj.totalRatings = order === 'asc' ? 1 : -1; // Secondary sort
            } else if (sort === 'price') {
                sortObj.hourlyRate = order === 'asc' ? 1 : -1;
            } else if (sort === 'distance' && latitude && longitude) {
                // For distance sorting, we'll use a different approach
                // since geospatial queries have sorting limitations
                sortObj.averageRating = -1; // Default to rating sort for distance queries
            }
            // Always add _id as final sort to ensure consistent pagination
            sortObj._id = 1;
            
            // Calculate pagination
            const pageNum = parseInt(page, 10);
            const limitNum = parseInt(limit, 10);
            const skip = (pageNum - 1) * limitNum;
            
            // Execute the query with pagination
            console.log('🔍 Final query object:', JSON.stringify(queryObj, null, 2));
            let providersQuery = Provider.find(queryObj)
                .select('-password') // Exclude sensitive data
                .skip(skip)
                .limit(limitNum);
            
            // Apply sorting (except for distance which is handled by geospatial query)
            if (sort !== 'distance') {
                providersQuery = providersQuery.sort(sortObj);
            }
            
            const [providers, total] = await Promise.all([
                providersQuery,
                Provider.countDocuments(queryObj)
            ]);
            
            console.log(`🔍 Search results: ${providers.length} providers found out of ${total} total`);
            
            // Debug: Log provider locations to see what we're working with
            if (providers.length > 0) {
                console.log('🔍 Provider locations found:');
                providers.forEach((provider, index) => {
                    let distanceInfo = '';
                    if (latitude && longitude && provider.location?.coordinates && provider.location.coordinates.length === 2) {
                        const providerLon = provider.location.coordinates[0];
                        const providerLat = provider.location.coordinates[1];
                        const userLat = parseFloat(latitude);
                        const userLon = parseFloat(longitude);
                        
                        // Calculate distance using Haversine formula
                        const R = 6371; // Earth's radius in km
                        const dLat = (providerLat - userLat) * Math.PI / 180;
                        const dLon = (providerLon - userLon) * Math.PI / 180;
                        const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                                Math.cos(userLat * Math.PI / 180) * Math.cos(providerLat * Math.PI / 180) *
                                Math.sin(dLon/2) * Math.sin(dLon/2);
                        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
                        const distance = R * c;
                        
                        distanceInfo = ` (Distance: ${distance.toFixed(2)}km)`;
                    }
                    
                    console.log(`  ${index + 1}. ${provider.fullName}:${distanceInfo}`);
                    console.log(`     Location: ${provider.location?.address || 'No address'}`);
                    console.log(`     City: ${provider.location?.city || 'No city'}`);
                    console.log(`     Coordinates: ${provider.location?.coordinates || 'No coordinates'}`);
                    console.log(`     Service Areas: ${provider.serviceAreas || 'None'}`);
                });
            }
            
            // Calculate total pages
            const totalPages = Math.ceil(total / limitNum);
            
            res.status(200).json({
                providers,
                currentPage: pageNum,
                totalPages,
                totalProviders: total,
                hasMore: pageNum < totalPages
            });
        } catch (error) {
            console.error('Error searching providers:', error);
            res.status(500).json({ message: 'Failed to search providers', error: error.message });
        }
    },

    // GET /api/providers/nearby - Find providers near a location
    async findNearbyProviders(req, res) {
        try {
            const {
                latitude,      // User's latitude
                longitude,     // User's longitude
                distance = 10, // Search radius in kilometers
                category,      // Service category
                page = 1,      // Page number
                limit = 10     // Results per page
            } = req.query;
            
            
            // Validate required parameters
            if (!latitude || !longitude) {
                return res.status(400).json({ message: 'Latitude and longitude are required' });
            }
            
            // Build the query object
            const queryObj = {
                accountStatus: 'active',
                verificationStatus: 'verified',
                'location.coordinates': {
                    $nearSphere: {
                        $geometry: {
                            type: 'Point',
                            coordinates: [parseFloat(longitude), parseFloat(latitude)]
                        },
                        $maxDistance: parseFloat(distance) * 1000 // Convert km to meters
                    }
                }
            };
            
            // Filter by category if provided
            if (category) {
                queryObj.serviceCategory = category;
            }
            
            
            // Calculate pagination
            const pageNum = parseInt(page, 10);
            const limitNum = parseInt(limit, 10);
            const skip = (pageNum - 1) * limitNum;
            
            // Execute the query with pagination
            const [providers, total] = await Promise.all([
                Provider.find(queryObj)
                    .select('-password') // Exclude sensitive data
                    .skip(skip)
                    .limit(limitNum),
                Provider.countDocuments(queryObj)
            ]);
            
            // Calculate total pages
            const totalPages = Math.ceil(total / limitNum);
            
            
            res.status(200).json({
                providers,
                currentPage: pageNum,
                totalPages,
                totalProviders: total,
                hasMore: pageNum < totalPages
            });
        } catch (error) {
            console.error('Error finding nearby providers:', error);
            res.status(500).json({ message: 'Failed to find nearby providers', error: error.message });
        }
    },

    // PATCH /api/providers/availability - Update provider availability
    async updateAvailability(req, res) {
        try {
            const { isAvailable } = req.body;
            const providerId = req.auth.id; // Fixed: Changed from req.user.id to req.auth.id

            if (typeof isAvailable !== 'boolean') {
                return res.status(400).json({ message: 'isAvailable must be a boolean' });
            }

            const provider = await Provider.findByIdAndUpdate(
                providerId,
                { isAvailable },
                { new: true }
            ).select('-password');

            if (!provider) {
                return res.status(404).json({ message: 'Provider not found' });
            }

            res.status(200).json({
                message: 'Availability updated successfully',
                provider
            });
        } catch (error) {
            console.error('Error updating availability:', error);
            res.status(500).json({ message: 'Failed to update availability', error: error.message });
        }
    },

    // GET /api/providers/categories - Get all service categories
    async getServiceCategories(req, res) {
        try {
            // This list should match the enum in the Provider model
            const categories = [
                { id: 'cleaning', name: 'Cleaning Services' },
                { id: 'home_repair', name: 'Home Repair & Maintenance' },
                { id: 'plumbing', name: 'Plumbing Services' },
                { id: 'electrical', name: 'Electrical Services' },
                { id: 'gardening', name: 'Gardening & Landscaping' },
                { id: 'moving', name: 'Moving & Delivery' },
                { id: 'tutoring', name: 'Tutoring & Education' },
                { id: 'pet_care', name: 'Pet Care Services' },
                { id: 'beauty', name: 'Beauty & Spa Services' },
                { id: 'wellness', name: 'Health & Wellness' },
                { id: 'photography', name: 'Photography & Videography' },
                { id: 'graphic_design', name: 'Graphic Design' },
                { id: 'web_development', name: 'Web Development' },
                { id: 'legal', name: 'Legal Services' },
                { id: 'automotive', name: 'Automotive Services' },
                { id: 'event_planning', name: 'Event Planning' },
                { id: 'personal_training', name: 'Personal Training' },
                { id: 'cooking', name: 'Cooking & Catering' },
                { id: 'delivery', name: 'Delivery Services' },
                { id: 'other', name: 'Other Services' }
            ];
            
            // Get count of providers in each category
            const categoryCounts = await Promise.all(
                categories.map(async (category) => {
                    const count = await Provider.countDocuments({
                        serviceCategory: category.id,
                        accountStatus: 'active'
                    });
                    return {
                        ...category,
                        providerCount: count
                    };
                })
            );
            
            res.status(200).json(categoryCounts);
        } catch (error) {
            console.error('Error getting service categories:', error);
            res.status(500).json({ message: 'Failed to get service categories', error: error.message });
        }
    },

    // PATCH /api/providers/update-location - Update provider location
    async updateLocation(req, res) {
        try {
            const providerId = req.auth.id;
            const { coordinates, address, city, state, zipCode, country } = req.body;
            
            
            // Validate the coordinates
            if (!coordinates || coordinates.length !== 2 || 
                !Array.isArray(coordinates) || 
                typeof coordinates[0] !== 'number' || 
                typeof coordinates[1] !== 'number') {
                return res.status(400).json({ 
                    message: 'Invalid coordinates. Expected [longitude, latitude] as numbers.' 
                });
            }
            
            const provider = await Provider.findById(providerId);
            if (!provider) {
                return res.status(404).json({ message: 'Provider not found' });
            }
            
            // Update location data
            provider.location = {
                type: 'Point',
                coordinates,
                address,
                city,
                state,
                zipCode,
                country: country || 'US'
            };
            
            const updatedProvider = await provider.save();
            
            res.status(200).json({ 
                message: 'Location updated successfully',
                location: updatedProvider.location,
                provider: {
                    fullName: updatedProvider.fullName,
                    businessName: updatedProvider.businessName,
                    email: updatedProvider.email
                }
            });
        } catch (error) {
            console.error('Error updating provider location:', error);
            res.status(500).json({ message: 'Failed to update location', error: error.message });
        }
    },

    // PATCH /api/providers/update-services - Update provider services
    async updateServices(req, res) {
        try {
            const providerId = req.auth.id;
            const { 
                serviceType, 
                serviceDescription, 
                serviceCategory, 
                serviceTags,
                hourlyRate
            } = req.body;
            
            
            const updateData = {};
            
            // Only update fields that are provided
            if (serviceType !== undefined) updateData.serviceType = serviceType;
            if (serviceDescription !== undefined) updateData.serviceDescription = serviceDescription;
            if (serviceCategory !== undefined) updateData.serviceCategory = serviceCategory;
            if (serviceTags !== undefined) updateData.serviceTags = serviceTags;
            if (hourlyRate !== undefined) updateData.hourlyRate = hourlyRate;
            
            // Perform the update
            const updatedProvider = await Provider.findByIdAndUpdate(
                providerId,
                { $set: updateData },
                { new: true, runValidators: true }
            ).select('-password');
            
            if (!updatedProvider) {
                return res.status(404).json({ message: 'Provider not found' });
            }
            
            res.status(200).json({ 
                message: 'Services updated successfully',
                provider: updatedProvider
            });
        } catch (error) {
            console.error('Error updating provider services:', error);
            if (error.name === 'ValidationError') {
                return res.status(400).json({ message: 'Validation error', errors: error.errors });
            }
            res.status(500).json({ message: 'Failed to update services', error: error.message });
        }
    },

    // DELETE /api/providers/me - Delete authenticated provider's account
    async deleteMyAccount(req, res) {
        const providerId = req.auth.id;
        
        if (!providerId) {
            return res.status(400).json({ message: 'Provider ID not found in authentication token.' });
        }

        if (!mongoose.Types.ObjectId.isValid(providerId)) {
            return res.status(400).json({ message: 'Invalid provider ID format.' });
        }

        try {
            // Find the provider first to make sure they exist
            const provider = await Provider.findById(providerId);
            
            if (!provider) {
                return res.status(404).json({ message: 'Provider not found.' });
            }

            // Delete the provider account
            await Provider.findByIdAndDelete(providerId);
            
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
            console.error('Error deleting provider account:', error);
            res.status(500).json({ 
                message: 'Failed to delete account', 
                error: error.message 
            });
        }
    }
};

module.exports = ProviderController;