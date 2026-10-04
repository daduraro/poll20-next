import type { UserModule } from '~/types'
// All files in locales/ (see the VueI18n plugin's `include` in vite.config.ts),
// precompiled at build time and keyed by file name (en, es, ca)
import messages from '@intlify/unplugin-vue-i18n/messages'
import { createI18n } from 'vue-i18n'

// locale in which translations appear in the code
const defaultLocale = 'en'

export const install: UserModule = ({ app }) => {
  const i18n = createI18n({
    legacy: false,
    locale: defaultLocale,
    messages,
  })

  app.use(i18n)
}
