import { defineConfig, devices } from '@playwright/test'

// Runs against an already running app (see compose.dev.yaml's `e2e` service).
// E2E_BASE_URL defaults to the Vite dev server.
export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  retries: 0,
  reporter: [['list']],
  use: {
    baseURL: process.env.E2E_BASE_URL ?? 'http://localhost:3333',
    trace: 'retain-on-failure',
  },
  projects: [
    { name: 'mobile', use: { ...devices['Pixel 7'] } },
  ],
})
