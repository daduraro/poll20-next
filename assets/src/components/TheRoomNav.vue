<script setup lang="ts">
import IconPoll from '~icons/mdi/poll'
import IconSettings from '~icons/carbon/settings'
import IconChart from '~icons/carbon/chart-pie'
import IconBookStack from '~icons/bx/collection'
import IconHistory from '~icons/material-symbols/history-rounded'

const { membership } = useUserStore()
const { t } = useI18n()

const links = computed(() => [
  {
    name: t('Votes'),
    route: { name: 'room-id' },
    icon: IconPoll,
  },
  {
    name: t('History'),
    route: { name: 'room-id-history' },
    icon: IconHistory,
  },
  {
    name: t('Statistics'),
    route: { name: 'room-id-statistics' },
    icon: IconChart,
  },
  {
    name: t('Games'),
    route: { name: 'room-id-games' },
    icon: IconBookStack,
  },
  {
    name: t('Settings'),
    route: { name: 'room-id-settings' },
    icon: IconSettings,
  },
])
</script>

<template>
  <nav class="text-xl text-center mb-6 flex border-1 border-red border-rounded items-center">
    <router-link
      v-for="(link, index) in links" :key="index"
      :to="{ ...link.route, params: membership.room }"
      v-aria-title="t('Go to {name}', link)"
      class="icon-btn text-2xl p-4 bg-red-400 flex-grow"
    >
      <component :is="link.icon" class="mx-auto"/>
    </router-link>
  </nav>
</template>

<style>
nav .icon-btn:hover {
  color: inherit;
}
nav .icon-btn:not(:last-child) {
  margin-right: 2px;
}
nav .icon-btn:not(.router-link-active) {
  background: transparent;
  font-weight: bold;
}
nav .icon-btn.router-link-active {
  opacity: 100%;
}
</style>