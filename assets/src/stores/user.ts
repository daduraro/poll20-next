import { acceptHMRUpdate, defineStore } from 'pinia'
import { type Room, type Member } from '~/types'

export type Membership = {
  room: Room;
  member_id: Member['id'];
}

export const useUserStore = defineStore('user', () => {
  const route = useRoute()
  const memberships = useLocalStorage<Membership[]>('pinia/memberships', [])

  const roomId = computed(() => route.params.id as string|undefined)
  const membership = computed(() => memberships.value.find(membership => membership.room.id === roomId.value))

  function join(membership: Membership) {
    memberships.value.push(membership)
  }

  function leave(room_id: Room['id']) {
    memberships.value.splice(memberships.value.findIndex(membership => membership.room.id === room_id), 1)
  }

  return { memberships, membership, join, leave }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useUserStore, import.meta.hot))
}
