/**
 * End-to-end tests: the real Nest app against a real PostgreSQL 17.
 * Locally an embedded PostgreSQL is started; in CI set TEST_DATABASE_URL
 * (a service container). Every response is checked against api/openapi.yaml.
 */
module.exports = {
  testEnvironment: 'node',
  rootDir: '..',
  roots: ['<rootDir>/test'],
  testRegex: '\\.e2e-spec\\.ts$',
  transform: { '^.+\\.ts$': ['ts-jest', { tsconfig: 'tsconfig.json' }] },
  moduleFileExtensions: ['ts', 'js', 'json'],
  globalSetup: '<rootDir>/test/global-setup.mjs',
  globalTeardown: '<rootDir>/test/global-teardown.mjs',
  testTimeout: 60000,
};
