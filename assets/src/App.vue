<script setup lang="ts">
const route = useRoute()

useHead({
  title: computed(() => 'Poll20' + (route.meta.title? ` - ${route.meta.title}` : '')),
  meta: [
    { name: 'description', content: 'Boardgame voting and logging' },
    {
      name: 'theme-color',
      content: computed(() => isDark.value ? '#00aba9' : '#ffffff'),
    },
  ],
  link: [
    {
      rel: 'icon',
      type: 'image/svg+xml',
      href: computed(() => preferredDark.value ? '/favicon-dark.svg' : '/favicon.svg'),
    },
  ],
})
</script>

<template>
  <RouterView />
</template>
