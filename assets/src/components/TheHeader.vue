<script setup lang="ts">
import logoXml from '~/assets/logo-themable.svg?raw'
const { t } = useI18n()
</script>

<template>
  <header class="text-center mb-4">
    <RouterLink class="icon-btn" :to="{ path: '/' }">
      <div
        style="fill: var(--main-color); width: 75px"
        v-html="logoXml"
      />
      <span class="sr-only">
        {{ t('Home') }}
      </span>
    </RouterLink>
  </header>
</template>