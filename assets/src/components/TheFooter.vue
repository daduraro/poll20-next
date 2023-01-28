<script setup lang="ts">
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
      <div i="carbon-sun dark:carbon-moon" />
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
      <div i-carbon-dicom-overlay />
    </RouterLink>
  </footer>
</template>
