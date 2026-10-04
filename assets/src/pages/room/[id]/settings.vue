<script setup lang="ts">
import type { Member } from '~/types'
import { vOnKeyStroke } from '@vueuse/components'

const { t } = useI18n()
const userStore = useUserStore()
// only rendered by room.vue when there is a membership
const membership = userStore.membership!
const deleteMembership = userStore.leave
const router = useRouter()

// =================
const inviteUrl = computed(() => location.origin + router.resolve({ name: '/join/[invite_code]', params: { invite_code: membership!.room.invite_code } }).href)
const copyUrl = useConfirmDialog()
copyUrl.onReveal(() => {
  navigator.clipboard.writeText(inviteUrl.value)
  setTimeout(copyUrl.confirm, 2000)
})

// =================
const kicking = ref(false)
const kickedMemberId = ref<Member['id'] | null>(null)
const confirmKick = useConfirmDialog()
confirmKick.onReveal((member_id: Member['id']) => {
  kickedMemberId.value = member_id
  setTimeout(confirmKick.cancel, 2000)
})
confirmKick.onCancel(() => kickedMemberId.value = null)
confirmKick.onConfirm(async () => {
  kicking.value = true
  const member_id = kickedMemberId.value!
  const { data, statusCode } = await useApi<Member>('patch', `rooms/${membership!.room.id!}/kick`, {
    attributes: { member_id },
  })
  kicking.value = false
  const members = membership!.room.members
  if (data.value) {
    members.splice(members.findIndex(member => member.id === member_id), 1)
    kickedMemberId.value = null
  }
  else if (statusCode.value === 400) {
    // refused: they logged a session since the members were loaded
    members.find(member => member.id === member_id)!.has_sessions = true
    kickedMemberId.value = null
  }
})

// =================
function toggleActive(roomMember: Member) {
  roomMember.active = !roomMember.active
  useApi<Member>('patch', `members/${roomMember.id}`, {
    attributes: {
      active: roomMember.active,
    },
  })
}

// =================
const updateNameButton = ref<HTMLButtonElement[] | null>(null)
const member = computed(() => membership.room.members.find(match => match.id === membership.member_id)!)
const name = ref(member.value.name)
async function updateName() {
  useApi<Member>('patch', `members/${membership!.member_id}`, {
    attributes: {
      name: name.value,
    },
  })
  member.value.name = name.value
}

// =================
const confirmLeave = useConfirmDialog()
confirmLeave.onReveal(() => setTimeout(confirmLeave.cancel, 2000))
confirmLeave.onConfirm(() => {
  deleteMembership(membership.room.id)
  router.push({ path: '/' })
})
</script>

<template>
  <p>{{ t('Members') }}</p>
  <p id="members-hint">
    {{ t('Inactive members don\'t appear in the poll. Members with logged sessions can\'t be kicked, make them inactive instead.') }}
  </p>
  <ul>
    <li v-for="roomMember in membership.room.members" :key="roomMember.id" class="mt-2 mb-6">
      <div class="flex items-center">
        <template v-if="roomMember.id !== membership.member_id">
          <button
            aria-live="assertive"
            class="btn btn-danger mr-4"
            :disabled="roomMember.has_sessions || (kicking && roomMember.id === kickedMemberId)"
            :aria-describedby="roomMember.has_sessions ? 'members-hint' : undefined"
            @click="() => kickedMemberId === roomMember.id
              ? confirmKick.confirm()
              : confirmKick.reveal(roomMember.id)"
            v-text="kickedMemberId === roomMember.id
              ? t('Click again to confirm')
              : t('Kick')"
          />
          <div class="flex-grow text-lg">
            {{ roomMember.name }}
          </div>
        </template>
        <template v-else>
          <input
            v-model="name"
            v-on-key-stroke:Enter="() => updateNameButton![0].click()"
            class="flex-grow min-w-0 text-lg"
          >
          <button
            ref="updateNameButton"
            :disabled="name === roomMember.name"
            class="btn ml-4 py-1!"
            style="white-space: nowrap"
            @click="updateName"
            v-text="t('Change name')"
          />
        </template>
        <label v-if="roomMember.id !== membership.member_id" class="flex items-center ml-4">
          <input
            type="checkbox"
            :checked="roomMember.active"
            aria-describedby="members-hint"
            class="mr-2"
            @change="toggleActive(roomMember)"
          >
          {{ t('Active') }}
        </label>
      </div>
    </li>
  </ul>
  <label>
    {{ t('Invite link:') }}
    <div class="flex mb-4">
      <input
        readonly
        :value="inviteUrl"
        class="flex-grow rounded-0! rounded-l!"
      >
      <button
        v-aria-title="copyUrl.isRevealed.value ? t('Copied!') : t('Copy to clipboard')"
        aria-live="polite"
        class="btn rounded-0! rounded-r!"
        @click="() => copyUrl.reveal()"
      >
        <i-carbon-copy v-if="!copyUrl.isRevealed.value" />
        <template v-else>
          {{ t('Copied!') }}
        </template>
      </button>
    </div>
  </label>

  <hr class="w-10% dark:opacity-40 mr-auto">

  <button
    aria-live="assertive"
    class="btn btn-danger w-100%"
    @click="() => confirmLeave.isRevealed.value ? confirmLeave.confirm() : confirmLeave.reveal()"
    v-text="confirmLeave.isRevealed.value
      ? t('Click again to confirm')
      : t('Leave room')"
  />
</template>

<route lang="yaml">
  meta:
    title: 'Settings'
</route>
