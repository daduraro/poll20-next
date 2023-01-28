<script setup lang="ts">
const { t } = useI18n()
</script>

<template>
  <header class="text-center mb-4">
    <RouterLink class="icon-btn" :to="{ path: '/' }">
      <i-carbon-campsite class="text-4xl" />
      <span class="sr-only">
        {{ t('Home') }}
      </span>
    </RouterLink>
  </header>
</template>
