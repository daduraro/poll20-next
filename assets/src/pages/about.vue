<script setup lang="ts">
import { format } from 'date-fns'

const buildDate = format(new Date(__BUILD_DATE__), 'Pp')
</script>

<template>
  <div class="prose dark:prose-invert m-auto text-left">
    <p>Poll20 by <a href="https://github.com/andres-ml" target="_blank" rel="noopener">andres-ml</a>.</p>
    <p>Built with</p>
    <ul>
      <li>Ash + Phoenix + Postgres</li>
      <li>Vue (Vitesse template)</li>
    </ul>
    <p>Last updated: {{ buildDate }}</p>
  </div>
</template>

<route lang="yaml">
meta:
  title: About
</route>
