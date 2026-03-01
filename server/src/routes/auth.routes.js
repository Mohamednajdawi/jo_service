const express = require('express');
const AuthController = require('../controllers/auth.controller');

const router = express.Router();

/**
 * @swagger
 * /auth/user/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *               - fullName
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 description: User's email address
 *               password:
 *                 type: string
 *                 minLength: 6
 *                 description: User's password (minimum 6 characters)
 *               fullName:
 *                 type: string
 *                 description: User's full name
 *               phoneNumber:
 *                 type: string
 *                 description: User's phone number
 *               profilePictureUrl:
 *                 type: string
 *                 description: URL to user's profile picture
 *     responses:
 *       201:
 *         description: User registered successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *                 token:
 *                   type: string
 *       400:
 *         description: Validation error or user already exists
 *       500:
 *         description: Server error
 */
router.post('/user/register', AuthController.registerUser);

/**
 * @swagger
 * /auth/user/login:
 *   post:
 *     summary: User login
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: User logged in successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *                 token:
 *                   type: string
 *       401:
 *         description: Invalid credentials
 *       500:
 *         description: Server error
 */
router.post('/user/login', AuthController.loginUser);

// User verification routes
router.get('/user/verify-email/:token', AuthController.verifyEmail);
router.post('/user/verify-phone', AuthController.verifyPhone);
router.post('/user/resend-verification', AuthController.resendVerificationCode);
router.post('/user/resend-email-verification', AuthController.resendEmailVerification);
router.get('/user/status/:userId', AuthController.getUserVerificationStatus);
router.post('/user/get-by-email', AuthController.getUserByEmail);

// OAuth routes
router.get('/oauth/:provider/initiate', AuthController.initiateOAuth);
router.post('/oauth/:provider/callback', AuthController.oauthCallback);

/**
 * @swagger
 * /auth/provider/login:
 *   post:
 *     summary: Provider login
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Provider logged in successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 provider:
 *                   $ref: '#/components/schemas/Provider'
 *                 token:
 *                   type: string
 *       401:
 *         description: Invalid credentials
 *       500:
 *         description: Server error
 */
router.post('/provider/login', AuthController.loginProvider);

module.exports = router; 