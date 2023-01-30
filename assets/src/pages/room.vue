<script setup lang="ts">
const { t } = useI18n()
const { membership } = useUserStore()
</script>

<template>
  <TheRoomNav v-if="membership"/>
  <main>
    <RouterView v-if="membership"/>
    <div class="text-right mt-8">
      <router-link :to="{ name: 'index' }">
        {{ t('Go back') }}
      </router-link>
    </div>
  </main>
</template>
