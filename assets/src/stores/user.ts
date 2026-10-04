import type { Game, Member, Room } from '~/types'
import { acceptHMRUpdate, defineStore } from 'pinia'
import { defaultFields } from '~/api-default-fields'

export interface Membership {
  room: Room & {
    members: Member[]
    games: Game[]
  }
  member_id: Member['id']
}

export const useUserStore = defineStore('user', () => {
  const storageKey = 'pinia/memberships'
  const memberships = ref<Membership[]>(
    JSON.parse(localStorage.getItem(storageKey) || JSON.stringify([])),
  )

  watch(memberships, value => localStorage.setItem(storageKey, JSON.stringify(value)), { deep: true })

  const route = useRoute()
  // the store is used from any page; only room pages have an `id` param
  const roomId = computed(() => 'id' in route.params ? route.params.id : undefined)
  const membership = computed(() => memberships.value.find(membership => membership.room.id === roomId.value))

  function join(membership: Membership) {
    memberships.value.push(membership)
  }

  function leave(room_id: Room['id']) {
    memberships.value.splice(memberships.value.findIndex(membership => membership.room.id === room_id), 1)
  }

  async function refreshMembership(current: Membership | undefined, previous: Membership | undefined = undefined) {
    if (current && !previous) {
      const { data } = await useApi<Membership['room']>('get', `rooms/${current.room.id}`, {
        query: {
          'include': [
            'members',
            'games.owners',
          ],
          // aggregates are only loaded on request, and listing fields replaces the defaults
          'fields[game]': [...defaultFields.game, 'last_played_at'].join(','),
        },
      })
      const room = data.value?.entity
      if (room) {
        memberships.value[memberships.value.findIndex(match => match.member_id === current!.member_id)].room = room
      }
    }
  }

  refreshMembership(membership.value)
  watch(membership, refreshMembership)

  return { memberships, membership, join, leave }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useUserStore, import.meta.hot))
}
