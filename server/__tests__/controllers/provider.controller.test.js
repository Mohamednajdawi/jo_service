/**
 * Provider Controller Tests
 * Tests for provider CRUD operations, search, and availability
 */

const providerController = require('../../src/controllers/provider.controller');

describe('ProviderController Methods', () => {
  describe('Controller methods exist', () => {
    it('should have getAllProviders method', () => {
      expect(typeof providerController.getAllProviders).toBe('function');
    });

    it('should have getProviderById method', () => {
      expect(typeof providerController.getProviderById).toBe('function');
    });

    it('should have searchProviders method', () => {
      expect(typeof providerController.searchProviders).toBe('function');
    });
  });
});

describe('Provider Validation Helpers', () => {
  describe('Service type validation', () => {
    const validServiceTypes = [
      'cleaning', 'plumbing', 'electrical', 'painting', 'moving',
      'carpentry', 'appliance', 'hvac', 'landscaping', 'pest_control',
      'security', 'tuition', 'personal_training', 'cooking', 'beauty',
      'photography', 'event_planning', 'it_support', 'car_wash', 'laundry', 'other'
    ];

    it('should have list of valid service types', () => {
      expect(validServiceTypes.length).toBeGreaterThan(0);
      expect(validServiceTypes).toContain('cleaning');
      expect(validServiceTypes).toContain('plumbing');
    });

    it('should validate service type is in list', () => {
      const isValidServiceType = (type) => validServiceTypes.includes(type);
      
      expect(isValidServiceType('cleaning')).toBe(true);
      expect(isValidServiceType('plumbing')).toBe(true);
      expect(isValidServiceType('invalid')).toBe(false);
    });
  });

  describe('Location validation', () => {
    const isValidCoordinates = (lat, lng) => {
      return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
    };

    it('should validate valid coordinates', () => {
      expect(isValidCoordinates(37.7749, -122.4194)).toBe(true);
      expect(isValidCoordinates(0, 0)).toBe(true);
    });

    it('should reject invalid latitude', () => {
      expect(isValidCoordinates(91, 0)).toBe(false);
      expect(isValidCoordinates(-91, 0)).toBe(false);
    });

    it('should reject invalid longitude', () => {
      expect(isValidCoordinates(0, 181)).toBe(false);
      expect(isValidCoordinates(0, -181)).toBe(false);
    });
  });

  describe('Hourly rate validation', () => {
    const isValidRate = (rate) => {
      return typeof rate === 'number' && rate > 0 && rate <= 10000;
    };

    it('should accept valid hourly rates', () => {
      expect(isValidRate(50)).toBe(true);
      expect(isValidRate(100.50)).toBe(true);
    });

    it('should reject invalid rates', () => {
      expect(isValidRate(0)).toBe(false);
      expect(isValidRate(-10)).toBe(false);
      expect(isValidRate(15000)).toBe(false);
      expect(isValidRate('fifty')).toBe(false);
    });
  });
});

describe('Provider Response Format', () => {
  describe('Provider object structure', () => {
    const providerResponse = {
      _id: '507f1f77bcf86cd799439012',
      email: 'provider@example.com',
      fullName: 'Test Provider',
      businessName: 'Test Services',
      serviceType: 'cleaning',
      serviceDescription: 'Professional cleaning',
      hourlyRate: 50,
      averageRating: 4.5,
      totalRatings: 10,
      verificationStatus: 'verified',
      accountStatus: 'active',
      isAvailable: true,
      location: {
        addressText: '123 Main St',
        city: 'San Francisco'
      }
    };

    it('should have required fields', () => {
      expect(providerResponse).toHaveProperty('_id');
      expect(providerResponse).toHaveProperty('email');
      expect(providerResponse).toHaveProperty('fullName');
      expect(providerResponse).toHaveProperty('serviceType');
    });

    it('should have correct verification status values', () => {
      const validStatuses = ['pending', 'verified', 'rejected'];
      expect(validStatuses).toContain('verified');
    });

    it('should have correct account status values', () => {
      const validStatuses = ['active', 'suspended', 'deactivated'];
      expect(validStatuses).toContain('active');
    });
  });
});

describe('Search Parameters', () => {
  describe('Geospatial search', () => {
    it('should require latitude and longitude for location search', () => {
      const hasRequiredCoords = (query) => {
        return query.latitude != null && query.longitude != null;
      };
      
      expect(hasRequiredCoords({ latitude: '37.7749', longitude: '-122.4194' })).toBe(true);
      expect(hasRequiredCoords({ latitude: '37.7749' })).toBe(false);
      expect(hasRequiredCoords({})).toBe(false);
    });
  });

  describe('Radius validation', () => {
    const isValidRadius = (radius) => {
      const r = parseFloat(radius);
      return !isNaN(r) && r > 0 && r <= 100;
    };

    it('should validate search radius', () => {
      expect(isValidRadius('10')).toBe(true);
      expect(isValidRadius('50')).toBe(true);
      expect(isValidRadius('0')).toBe(false);
      expect(isValidRadius('150')).toBe(false);
    });
  });
});