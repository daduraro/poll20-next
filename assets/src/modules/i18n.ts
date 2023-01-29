import { createI18n } from 'vue-i18n'
import { type UserModule } from '~/types'

// Import i18n resources
const localeFiles = import.meta.glob<{ default: any }>('../../locales/*.y(a)?ml', { eager: true })
const messages = Object.fromEntries(
  Object.entries(localeFiles).map(([key, value]) => {
    const extensionLength = key.endsWith('.yaml') ? -5 : -4
    return [key.slice('../../locales/'.length, extensionLength), value.default]
  })
)

// e.g. es-ES -> es // ca_ES -> ca // EN -> en
const normalizeLocale = (locale: string) => locale.toLowerCase().match(/[a-z]+/)?.[0]
const defaultLocale = 'en'
const defaultMessages = Object.fromEntries(
  Object.keys(messages[Object.keys(messages)[0]]).map(key => [key, key])
)

export const install: UserModule = ({ app }) => {
  const i18n = createI18n({
    legacy: false,
    locale: normalizeLocale(navigator.language) || 'en',
    messages: {
      [defaultLocale]: defaultMessages,
      ...messages
    },
  })

  app.use(i18n)
}
