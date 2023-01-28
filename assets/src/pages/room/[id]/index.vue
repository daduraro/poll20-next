<script setup lang="ts">
const { membership, leave: deleteMembership } = useUserStore()
const router = useRouter()

async function leaveRoom() {
    deleteMembership(membership.room.id)
    router.push({ path: '/' })
}
</script>

<template>
  <div>
    <button
      class="btn"
      @click="leaveRoom"
    >
      leave
    </button>
  </div>
</template>
