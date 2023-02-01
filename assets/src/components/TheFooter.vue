<script setup lang="ts">
import IconMoon from '~icons/carbon/moon'
import IconSun from '~icons/carbon/sun'
const { t, availableLocales, locale } = useI18n()
const route = useRoute()
const router = useRouter()

// e.g. es-ES -> es // ca_ES -> ca // EN -> en
const normalizeLocale = (locale: string) => locale.toLowerCase().match(/[a-z]+/)?.[0]
const savedLocale = useLocalStorage('i18n.locale', normalizeLocale(navigator.language))
locale.value = savedLocale.value!
watch(locale, value => savedLocale.value = value)
const cycleLocales = () => {
  const locales = availableLocales
  locale.value = locales[(locales.indexOf(locale.value) + 1) % locales.length]
}

const mainColor = useLocalStorage('theming.color', 'red')
const availableColors = ['red', 'green', 'blue']
const cycleColor = () => {
  mainColor.value = availableColors[(availableColors.indexOf(mainColor.value) + 1) % availableColors.length]
}
watch(mainColor, (value) => {
  document.querySelector('html')!.setAttribute('main-color', value)
}, {
  immediate: true
})
</script>

<template>
  <footer class="text-xl text-center mt-10 justify-center flex">
    <button
      v-aria-title="t('Toggle dark mode')"
      class="icon-btn mx-2"
      @click="toggleDark()"
    >
      <component :is="isDark ? IconMoon : IconSun" />
    </button>

  <button
    v-aria-title="t('Change color')"
    class="icon-btn mx-2"
    style="background-color: var(--main-color); border-radius: 100%; padding: 0.65rem;"
    @click="cycleColor()"
  />

    <button
      v-aria-title="t('Change language')"
      class="icon-btn mx-2"
      @click="cycleLocales()"
    >
      [{{ locale }}]
    </button>

    <RouterLink
      v-if="route.path !== '/about'"
      to="/about"
      v-aria-title="t('About')"
      class="icon-btn mx-2"
    >
      <i-carbon-dicom-overlay />
    </RouterLink>

    <button
      v-else
      v-aria-title="t('Go back')"
      to="/about"
      class="icon-btn mx-2"
      @click="router.back()"
    >
      <i-fa-solid-arrow-left />
    </button>
  </footer>
</template>
