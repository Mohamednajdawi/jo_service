/**
 * JWT Utils Tests
 */

describe('JWT Utils', () => {
  const originalEnv = process.env;
  let generateToken, verifyToken;

  beforeAll(() => {
    process.env.JWT_SECRET = 'test_secret_key_for_jwt_testing_only';
    process.env.JWT_EXPIRES_IN = '1h';
  });

  beforeEach(() => {
    jest.resetModules();
    process.env.JWT_SECRET = 'test_secret_key_for_jwt_testing_only';
    process.env.JWT_EXPIRES_IN = '1h';
    const jwt = require('../../src/utils/jwt.utils');
    generateToken = jwt.generateToken;
    verifyToken = jwt.verifyToken;
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  describe('generateToken', () => {
    it('should generate a valid JWT token', () => {
      const payload = { id: '507f1f77bcf86cd799439011', type: 'user' };
      const token = generateToken(payload);

      expect(token).toBeDefined();
      expect(typeof token).toBe('string');
      expect(token.split('.')).toHaveLength(3);
    });

    it('should throw error when payload is missing id', () => {
      expect(() => {
        generateToken({ type: 'user' });
      }).toThrow('Token generation failed: payload must include id and type.');
    });

    it('should throw error when payload is missing type', () => {
      expect(() => {
        generateToken({ id: '507f1f77bcf86cd799439011' });
      }).toThrow('Token generation failed: payload must include id and type.');
    });

    it('should include correct payload in token', () => {
      const payload = { id: 'user123', type: 'provider' };
      const token = generateToken(payload);
      const decoded = verifyToken(token);

      expect(decoded.id).toBe('user123');
      expect(decoded.type).toBe('provider');
    });
  });

  describe('verifyToken', () => {
    it('should verify a valid token', () => {
      const payload = { id: '507f1f77bcf86cd799439011', type: 'user' };
      const token = generateToken(payload);
      const decoded = verifyToken(token);

      expect(decoded).toBeDefined();
      expect(decoded.id).toBe(payload.id);
      expect(decoded.type).toBe(payload.type);
    });

    it('should return null for invalid token', () => {
      const result = verifyToken('invalid.token.here');
      expect(result).toBeNull();
    });

    it('should return null for empty string token', () => {
      const result = verifyToken('');
      expect(result).toBeNull();
    });

    it('should return null for null token', () => {
      const result = verifyToken(null);
      expect(result).toBeNull();
    });
  });
});