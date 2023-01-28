<script setup lang="ts">
import IconMoon from '~icons/carbon/moon'
import IconSun from '~icons/carbon/sun'
const { t, availableLocales, locale } = useI18n()

const toggleLocales = () => {
  const locales = availableLocales
  locale.value = locales[(locales.indexOf(locale.value) + 1) % locales.length]
}
</script>

<template>
  <footer class="text-xl text-center mt-10 justify-center items-center flex">
    <button
      v-aria-title="t('Toggle dark mode')"
      class="icon-btn mx-2"
      @click="toggleDark()"
    >
      <component :is="isDark ? IconMoon : IconSun" />
    </button>

    <button
      v-aria-title="t('Toggle language')"
      class="icon-btn mx-2"
      @click="toggleLocales()"
    >
      [{{ locale }}]
    </button>

    <RouterLink
      to="/about"
      v-aria-title="t('About')"
      class="icon-btn mx-2"
    >
      <i-carbon-dicom-overlay />
    </RouterLink>
  </footer>
</template>
