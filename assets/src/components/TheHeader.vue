<script setup lang="ts">
const { t } = useI18n()
</script>

<template>
  <header class="text-center mb-4">
    <RouterLink class="icon-btn" :to="{ path: '/' }">
      <div class="text-4xl i-carbon-campsite" />
      <span class="sr-only">
        {{ t('Home') }}
      </span>
    </RouterLink>
  </header>
</template>
