<script setup lang="ts">
const props = defineProps<{ name: string }>()
const router = useRouter()
onMounted(() => {
  fetch("http://127.0.0.1:4000/api/members")
})
</script>

<template>
  <div>
    ok
  </div>
</template>
