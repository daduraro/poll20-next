import type { Locale } from 'date-fns'
import { setDefaultOptions } from 'date-fns'

// every date-fns locale as its own lazy chunk, keyed by tag (`ca`, `en-GB`, ...)
const localeLoaders = Object.fromEntries(
  Object
    .entries(import.meta.glob<Locale>('/node_modules/date-fns/locale/*.js', { import: 'default' }))
    .map(([path, loader]) => [path.match(/([^/]+)\.js$/)![1], loader]),
)

// first browser language with a matching date-fns locale, trying the full tag before the bare language
// (`ca-ES` -> `ca`); date-fns's own default (en-US) stays when none matches
function findLocaleLoader() {
  for (const language of navigator.languages) {
    const [baseLanguage] = language.split('-')
    const loader = localeLoaders[language] ?? localeLoaders[baseLanguage]
    if (loader)
      return loader
  }
}

// date formatting follows the browser's locale, independently of the app's translations;
// date-fns isn't reactive, so this has to finish before anything renders a date
export async function loadDateFnsLocale() {
  const locale = await findLocaleLoader()?.()
  if (locale)
    setDefaultOptions({ locale })
}
