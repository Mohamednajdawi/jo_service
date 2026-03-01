const express = require('express');
const ProviderController = require('../controllers/provider.controller');
const { protectRoute, isProvider } = require('../middlewares/auth.middleware');
const upload = require('../middlewares/upload.middleware');

const router = express.Router();

/**
 * @swagger
 * /providers:
 *   get:
 *     summary: Get all providers with pagination
 *     tags: [Providers]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Number of providers per page
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: Filter by service category
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search providers by name or service
 *     responses:
 *       200:
 *         description: List of providers
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 providers:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Provider'
 *                 currentPage:
 *                   type: integer
 *                 totalPages:
 *                   type: integer
 *                 totalProviders:
 *                   type: integer
 */
router.get('/', ProviderController.getAllProviders);

/**
 * @swagger
 * /providers/search:
 *   get:
 *     summary: Search providers with filters
 *     tags: [Providers]
 *     parameters:
 *       - in: query
 *         name: q
 *         schema:
 *           type: string
 *         description: Search query
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: Service category filter
 *       - in: query
 *         name: location
 *         schema:
 *           type: string
 *         description: Location filter
 *     responses:
 *       200:
 *         description: Search results
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 providers:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Provider'
 */
router.get('/search', ProviderController.searchProviders);

/**
 * @swagger
 * /providers/nearby:
 *   get:
 *     summary: Find providers near a location
 *     tags: [Providers]
 *     parameters:
 *       - in: query
 *         name: latitude
 *         required: true
 *         schema:
 *           type: number
 *         description: Latitude coordinate
 *       - in: query
 *         name: longitude
 *         required: true
 *         schema:
 *           type: number
 *         description: Longitude coordinate
 *       - in: query
 *         name: radius
 *         schema:
 *           type: number
 *           default: 10
 *         description: Search radius in kilometers
 *     responses:
 *       200:
 *         description: Nearby providers
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Provider'
 */
router.get('/nearby', ProviderController.findNearbyProviders);

/**
 * @swagger
 * /providers/categories:
 *   get:
 *     summary: Get all service categories
 *     tags: [Providers]
 *     responses:
 *       200:
 *         description: List of service categories
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: string
 */
router.get('/categories', ProviderController.getServiceCategories);

/**
 * @swagger
 * /providers/profile/me:
 *   get:
 *     summary: Get the logged-in provider's profile
 *     tags: [Providers]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Provider profile
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Provider'
 *       401:
 *         description: Unauthorized
 */
router.get('/profile/me', protectRoute, isProvider, ProviderController.getMyProfile);

/**
 * @swagger
 * /providers/profile:
 *   patch:
 *     summary: Update the logged-in provider's profile
 *     tags: [Providers]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               fullName:
 *                 type: string
 *               businessName:
 *                 type: string
 *               serviceType:
 *                 type: string
 *               serviceDescription:
 *                 type: string
 *               hourlyRate:
 *                 type: number
 *               phoneNumber:
 *                 type: string
 *     responses:
 *       200:
 *         description: Profile updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 provider:
 *                   $ref: '#/components/schemas/Provider'
 *       401:
 *         description: Unauthorized
 */
router.patch('/profile', protectRoute, isProvider, ProviderController.updateMyProfile);

/**
 * @swagger
 * /providers/update-location:
 *   patch:
 *     summary: Update provider location
 *     tags: [Providers]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - latitude
 *               - longitude
 *             properties:
 *               latitude:
 *                 type: number
 *               longitude:
 *                 type: number
 *               address:
 *                 type: string
 *               city:
 *                 type: string
 *               state:
 *                 type: string
 *               zipCode:
 *                 type: string
 *     responses:
 *       200:
 *         description: Location updated successfully
 *       401:
 *         description: Unauthorized
 */
router.patch('/update-location', protectRoute, isProvider, ProviderController.updateLocation);

/**
 * @swagger
 * /providers/update-services:
 *   patch:
 *     summary: Update provider services
 *     tags: [Providers]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               serviceType:
 *                 type: string
 *               serviceDescription:
 *                 type: string
 *               serviceCategory:
 *                 type: string
 *               serviceTags:
 *                 type: array
 *                 items:
 *                   type: string
 *               hourlyRate:
 *                 type: number
 *               availability:
 *                 type: object
 *     responses:
 *       200:
 *         description: Services updated successfully
 *       401:
 *         description: Unauthorized
 */
router.patch('/update-services', protectRoute, isProvider, ProviderController.updateServices);

/**
 * @swagger
 * /providers/profile-picture:
 *   post:
 *     summary: Upload provider profile picture
 *     tags: [Providers]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               profilePicture:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: Profile picture uploaded successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 provider:
 *                   $ref: '#/components/schemas/Provider'
 *       401:
 *         description: Unauthorized
 */
router.post('/profile-picture', protectRoute, isProvider, upload.single('profilePicture'), ProviderController.uploadProfilePicture);

/**
 * @swagger
 * /providers/availability:
 *   patch:
 *     summary: Update provider availability
 *     tags: [Providers]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               isAvailable:
 *                 type: boolean
 *                 description: Provider availability status
 *     responses:
 *       200:
 *         description: Availability updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 provider:
 *                   $ref: '#/components/schemas/Provider'
 *       400:
 *         description: Invalid request body
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Provider not found
 */
router.patch('/availability', protectRoute, isProvider, ProviderController.updateAvailability);

/**
 * @swagger
 * /providers/{id}:
 *   get:
 *     summary: Get a specific provider by ID
 *     tags: [Providers]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Provider ID
 *     responses:
 *       200:
 *         description: Provider details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Provider'
 *       404:
 *         description: Provider not found
 */
router.get('/:id', ProviderController.getProviderById);

// DELETE /api/providers/me - Delete provider account
router.delete('/me', protectRoute, isProvider, ProviderController.deleteMyAccount);

module.exports = router; 