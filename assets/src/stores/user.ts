import { acceptHMRUpdate, defineStore } from 'pinia'
import {
  type Room,
  type Member,
  type Game
} from '~/types'

export type Membership = {
  room: Room & { 
    members: Member[];
    games: Game[];
  };
  member_id: Member['id'];
}

export const useUserStore = defineStore('user', () => {
  const storageKey = 'pinia/memberships'
  const memberships = ref<Membership[]>(
    JSON.parse(localStorage.getItem(storageKey) || JSON.stringify([]))
  )
  
  watch(memberships, value => localStorage.setItem(storageKey, JSON.stringify(value)), {deep: true})
  
  const route = useRoute()
  const roomId = computed(() => route?.params.id as string|undefined)
  const membership = computed(() => memberships.value.find(membership => membership.room.id === roomId.value))

  function join(membership: Membership) {
    memberships.value.push(membership)
  }

  function leave(room_id: Room['id']) {
    memberships.value.splice(memberships.value.findIndex(membership => membership.room.id === room_id), 1)
  }

  async function refreshMembership(current: Membership|undefined, previous: Membership|undefined = undefined) {
    if (current && !previous) {
      const { data } = await useApi<Room>('get', `rooms/${current.room.id}`, {
        query: {
          include: [
            'members',
            'games.owners',
          ]
        }
      })
      memberships.value[memberships.value.findIndex(match => match.member_id === current!.member_id)].room = data.value.entity
    }
  }

  refreshMembership(membership.value)
  watch(membership, refreshMembership)

  return { memberships, membership, join, leave }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useUserStore, import.meta.hot))
}
