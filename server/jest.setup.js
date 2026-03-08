// Jest setup file

global.beforeEach(() => {
  // Reset all mocks before each test
  jest.clearAllMocks();
});

// Suppress console during tests unless verbose
if (process.env.JEST_VERBOSE !== 'true') {
  global.console = {
    ...console,
    log: jest.fn(),
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  };
}

// Set test timeout
jest.setTimeout(10000);