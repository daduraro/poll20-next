<script setup lang="ts">
import { Member, Room } from '~/types';

const { t } = useI18n()
const route = useRoute('/join/[invite_code]')
const { join: addMembership, memberships } = useUserStore()

// load room
type RoomWithMembers = Room & { members: Member[] }
const { data, onFetchResponse } = useApi<RoomWithMembers>('get', 'rooms', {
  query: {
    invite_code: route.params.invite_code,
    include: 'members',
  }
})
const room = computed(() => data.value?.entities?.[0])
// redirect to room if already a member
onFetchResponse(() => {
  if (memberships.some(membership => membership.room.id === room.value?.id)) {
    router.push({ name: '/room/[id]/poll', params: { id: room.value!.id } })
  }
})

// join room logic
let busy = ref(false)
const newMember = ref({ name: '' })
const router = useRouter()
const form = [
  {
    id: 'name',
    label: t('Your name'),
    is: 'input',
    attrs: {
      type: 'text',
      required: true,
    },
  }
]

function joinWith(room: RoomWithMembers, member: Member) {
  // games are loaded by the user store once the membership is active
  const membership = { room: { games: [], ...room }, member_id: member.id }
  addMembership(membership)
  router.push({ name: '/room/[id]/poll', params: { id: membership.room.id } })
}

// create a new member and join as that one
async function addMemberAndJoin() {
  busy.value = true
  const join = await useApi<RoomWithMembers>('patch', `/rooms/${room.value!.id}/join`, {
    query: {
      invite_code: room.value!.invite_code,
      include: 'members'
    },
    attributes: {
      name: newMember.value.name
    }
  })
  busy.value = false
  const joined = join.data.value?.entity
  if (!joined) {
    throw join.error.value
  }
  joinWith(joined, joined.members[joined.members.length - 1])
}
</script>

<template>
  <div v-if="room">
    <h1 class="text-lg text-center mb-4">
      <i18n-t keypath="You have been invited to {name}">
        <template #name>
          <strong class="text-2xl">{{ room.name }}</strong>
        </template>
      </i18n-t>
    </h1>
    <ul>
      <li v-for="member in room.members" :key="member.id" class="mb-4">
        <button class="btn-link text-lg" @click="joinWith(room!, member)">
          <i18n-t keypath="Join as {name}">
            <template #name>
              <strong>{{ member.name }}</strong>
            </template>
          </i18n-t>
        </button>
      </li>
    </ul>
    {{ t('Or...') }}
    <p-form
      v-model:value="newMember"
      :title="t('Join as new member')"
      :definition="form"
      :busy="busy"
      :submit-label="t('Join')"
      @submit="addMemberAndJoin"
    />
  </div>
</template>
