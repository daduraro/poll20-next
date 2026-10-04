import type { UserModule } from './types'
import { createHead } from '@unhead/vue/client'
import { setupLayouts } from 'virtual:generated-layouts'
import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import { routes } from 'vue-router/auto-routes'
import App from './App.vue'

import '@unocss/reset/tailwind.css'
import './styles/main.css'
import 'uno.css'

const app = createApp(App)
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: setupLayouts(routes),
})

// install all modules under `modules/`
Object
  .values(import.meta.glob<{ install: UserModule }>('./modules/*.ts', { eager: true }))
  .forEach(i => i.install?.({ app, router }))

app.use(router)
app.use(createHead())
app.mount('#app')

// treat role="button" as such
document.addEventListener('keydown', (event: KeyboardEvent) => {
  const target = event.target as any
  if (target?.matches('[aria-role="button"]') && ['Enter', ' '].includes(event.key)) {
    target.click()
    event.preventDefault()
  }
})
