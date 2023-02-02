<script setup lang="ts">
import { randomPick } from '~/lib/utils/array'
import { rooms as roomSamples } from '~/lib/samples'
import { Room } from '~/types'
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
      if (!create.data.value.entity) {
        throw create.error.value
      }
      
      const join = await useApi<Room>('patch', `/rooms/${create.data.value.entity.id}/join`, {
        query: {
          invite_code: create.data.value.entity.invite_code,
          include: 'members'
        },
        attributes: {
          name: newRoom.value.memberName
        }
      })

      if (!join.data.value.entity) {
        throw join.error
      }

      const membership = {
        room: join.data.value.entity,
        member_id: join.data.value.entity.members[join.data.value.entity.members.length - 1].id,
      }
      addMembership(membership)
      router.push({ name: 'room-id-settings', params: membership.room })
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
          <router-link :to="{ name: 'room-id-poll', params: membership.room }" class="text-xl">
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