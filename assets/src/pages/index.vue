<script setup lang="ts">
import { randomPick } from '~/lib/utils/array'
import { rooms as roomSamples } from '~/lib/samples'
import { Member, Room } from '~/types'
import { useApi } from '~/composables/api'

const { t } = useI18n()
const router = useRouter()
const { memberships, join: addMembership } = useUserStore()

const sampleValue = randomPick(roomSamples)

const form = computed(() => [
  {
    id: 'roomName',
    label: t('Room name'),
    is: 'input',
    attrs: {
      type: 'text',
      required: true,
      placeholder: sampleValue.roomName,
    },
  },
  {
    id: 'memberName',
    label: t('Your name'),
    is: 'input',
    attrs: {
      type: 'text',
      required: true,
      placeholder: sampleValue.memberName,
    },
  },
])

const newRoom = ref({
  roomName: '',
  memberName: '',
})

const busy = ref(false)
async function createRoom(): Promise<void> {
    busy.value = true
    try {
      const create = await useApi<Room>('post', '/rooms', {
        attributes: {
          name: newRoom.value.roomName
        }
      })
      const created = create.data.value?.entity
      if (!created) {
        throw create.error.value
      }

      const join = await useApi<Room & { members: Member[] }>('patch', `/rooms/${created.id}/join`, {
        query: {
          invite_code: created.invite_code,
          include: 'members'
        },
        attributes: {
          name: newRoom.value.memberName
        }
      })
      const joined = join.data.value?.entity
      if (!joined) {
        throw join.error.value
      }

      const membership = {
        // a new room has no games
        room: { games: [], ...joined },
        member_id: joined.members[joined.members.length - 1].id,
      }
      addMembership(membership)
      router.push({ name: '/room/[id]/settings', params: { id: membership.room.id } })
    } finally {
      busy.value = false
    }
}
</script>

<template>
  <main>
    <div v-if="memberships.length > 0">
      <h1 class="text-lg text-left">
        {{ t('Your rooms:') }}
      </h1>
      <ul>
        <li v-for="membership in memberships" :key="membership.room.id" class="my-3">
          <router-link :to="{ name: '/room/[id]/poll', params: { id: membership.room.id } }" class="text-xl">
            {{ membership.room.name }}
          </router-link>
        </li>
      </ul>
      <hr class="my-2"/>
      {{ t('Or...') }}
    </div>
    <h1 v-else class="mb-4">
      {{ t('You have no rooms yet. Create one or get a friend\'s invite!') }}
    </h1>
    <p-form
      v-model:value="newRoom"
      :title="t('Create room')"
      :definition="form"
      :busy="busy"
      @submit="createRoom"
    />
  </main>
</template>