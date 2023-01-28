<script setup lang="ts">
import { randomPick } from '~/lib/utils/array'
import { rooms as roomSamples } from '~/lib/samples'
import { Room } from '~/types'
import { useApi } from '~/composables/api'

const { t } = useI18n()
const router = useRouter()
const { memberships, join: addMembership } = useUserStore()

const sampleValue = randomPick(roomSamples)

const form = [
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
]

const newRoom = ref({
  roomName: 'a',
  memberName: 'b',
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

      if (!create.entity.value) {
        throw create.error
      }
      
      const join = await useApi<Room>('patch', `/rooms/${create.entity.value.id}/join`, {
        query: {
          invite_code: create.entity.value!.invite_code,
          include: 'members'
        },
        attributes: {
          name: newRoom.value.memberName
        }
      })

      if (!join.entity.value) {
        throw join.error
      }

      console.log(join.entity.value)
      const membership = {
        room: join.entity.value,
        member_id: join.entity.value.members[join.entity.value.members.length - 1].id,
      }
      addMembership(membership)
      router.push({ name: 'room-id', params: membership.room })
    } finally {
      busy.value = false
    }
}
</script>

<template>
  <div>
    <div v-if="memberships.length > 0">
      <p>Your rooms:</p>
      <ul>
        <li v-for="membership in memberships" :key="membership.room.id" class="my-3">
          <router-link :to="{ name: 'room-id', params: membership.room }" class="text-xl">
            {{ membership.room.name }}
          </router-link>
        </li>
      </ul>
    </div>
    <p v-else>
      {{ t('You have no rooms yet. Create one or get a friend\'s invite!') }}
    </p>
    <hr class="my-2"/>
    {{ t('Or...') }}
    <p-form
      v-model:value="newRoom"
      :title="t('Create room')"
      :definition="form"
      :busy="busy"
      @submit="createRoom"
    />
  </div>
</template>