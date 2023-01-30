<script setup lang="ts">
import { Member } from '~/types'
import { vOnKeyStroke } from '@vueuse/components'

const { t } = useI18n()
const { membership, leave: deleteMembership } = useUserStore()
const router = useRouter()

// =================
const inviteUrl = computed(() => location.origin + router.resolve({ name: 'join-invite_code', params: membership!.room }).href)
const copyUrl = useConfirmDialog()
copyUrl.onReveal(() => {
  navigator.clipboard.writeText(inviteUrl.value)
  setTimeout(copyUrl.confirm, 2000)
})

// =================
const kicking = ref(false)
const kickedMemberId = ref<Member['id']|null>(null)
const confirmKick = useConfirmDialog()
confirmKick.onReveal((member_id: Member['id']) => {
  kickedMemberId.value = member_id
  setTimeout(confirmKick.cancel, 2000)
})
confirmKick.onCancel(() => kickedMemberId.value = null)
confirmKick.onConfirm(async () => {
  kicking.value = true
  const member_id = kickedMemberId.value!
  const { data } = await useApi<Member>('patch', `rooms/${membership!.room.id!}/kick`, {
    attributes: { member_id }
  })
  kicking.value = false
  if (data.value) {
    membership!.room.members.splice(membership!.room.members.findIndex(member => member.id === member_id), 1)
    kickedMemberId.value = null
  }
})

// =================
const updateNameButton = ref<HTMLButtonElement[]|null>(null)
const member = computed(() => membership?.room.members.find(match => match.id === membership?.member_id))
const name = ref(member.value.name)
async function updateName() {
  useApi<Member>('patch', `members/${membership!.member_id}`, {
    attributes: {
      name: name.value
    }
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
  <ul>
    <li v-for="member in membership.room.members" :key="member.id" class="mt-2 mb-6">
      <div v-if="member.id !== membership.member_id" class="flex">
        <button
          v-if="member.id !== membership.member_id"
          aria-live="assertive"
          class="btn btn-danger mr-4"
          :disabled="kicking && member.id === kickedMemberId"
          @click="() => kickedMemberId === member.id
            ? confirmKick.confirm()
            : confirmKick.reveal(member.id)"
          v-text="kickedMemberId === member.id
            ? t('Click again to confirm')
            : t('Kick')"
        />
        <div class="flex-grow text-lg">{{ member.name }}</div>
      </div>
      <div v-else class="flex">
        <input
          v-on-key-stroke:Enter="() => updateNameButton![0].click()"
          v-model="name"
          class="input flex-grow text-lg"
        >
        <button
          ref="updateNameButton"
          :disabled="name === member.name"
          class="btn ml-4"
          @click="updateName"
          v-text="t('Change name')"
        />
      </div>
    </li>
  </ul>
  <label>
    {{ t('Invite link:') }}
    <div class="flex mb-4">
      <input
        readonly
        :value="inviteUrl"
        class="input flex-grow rounded-0 rounded-l"
      />
      <button
        aria-live="polite"
        v-aria-title="copyUrl.isRevealed.value ? t('Copied!') : t('Copy to clipboard')"
        class="btn rounded-0 rounded-r"
        @click="() => copyUrl.reveal()"
      >
        <i-carbon-copy v-if="!copyUrl.isRevealed.value"/>
        <template v-else>
          {{ t('Copied!') }}
        </template>
      </button>
    </div>
  </label>

  <hr class="w-10% dark:opacity-40 mr-auto"/>

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