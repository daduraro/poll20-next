import { ViteSSG } from 'vite-ssg'
import { setupLayouts } from 'virtual:generated-layouts'
import Previewer from 'virtual:vue-component-preview'
import App from './App.vue'
import type { UserModule } from './types'
import generatedRoutes from '~pages'

import '@unocss/reset/tailwind.css'
import './styles/main.css'
import 'uno.css'

const routes = setupLayouts(generatedRoutes)

// https://github.com/antfu/vite-ssg
export const createApp = ViteSSG(
  App,
  {
    routes,
    base: import.meta.env.BASE_URL
  },
  (context) => {
    context.initialState = {
      pinia: {
        rooms: [],
      },
    }

    // install all modules under `modules/`
    Object
      .values(import.meta.glob<{ install: UserModule }>('./modules/*.ts', { eager: true }))
      .forEach(i => i.install?.(context))
    
    context.app.use(Previewer)
  },
)

// treat role="button" as such
document.addEventListener('keydown', (event: KeyboardEvent) => {
  const target = event.target as any
  if (target?.matches('[aria-role="button"]') && ['Enter', ' '].includes(event.key)) {
    target.click()
    event.preventDefault()
  }
})