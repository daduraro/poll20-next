<script setup lang="ts">
import type { Attendee, Game, Member, Session } from '~/types'
import { formatRelative } from 'date-fns'
import { compose, sortBy } from 'ramda'

const route = useRoute()
const { t } = useI18n()
const { membership } = useUserStore()
const games = computed(() => sortBy(game => game.name.toLowerCase(), membership?.room.games ?? []))

const pageSize = 20
// empty for every game
const filterGameId = ref<Game['id'] | ''>('')

type SessionWithMembers = Session & { attendees: (Attendee & { member: Member })[] }
const loadedSessions = ref<SessionWithMembers[]>([])
const hasLoaded = ref(false)
const hasMore = ref(false)
const isLoading = ref(false)
// a response for a previous filter must not land in the list of the current one
let latestRequest = 0

async function loadSessions(reset = false) {
  const request = ++latestRequest
  isLoading.value = true
  const { data } = await useApi<SessionWithMembers>('get', 'sessions', {
    query: {
      'include': ['attendees.member', 'game'],
      'sort': '-inserted_at',
      'page[limit]': pageSize,
      'page[offset]': reset ? 0 : loadedSessions.value.length,
      ...(filterGameId.value ? { 'filter[game_id]': filterGameId.value } : {}),
    },
  })
  if (request !== latestRequest) {
    return
  }

  const page = data.value?.entities ?? []
  // sessions logged since the previous page shift the offsets, which would repeat some
  const loadedIds = new Set(reset ? [] : loadedSessions.value.map(session => session.id))
  loadedSessions.value = (reset ? [] : loadedSessions.value)
    .concat(page.filter(session => !loadedIds.has(session.id)))
  hasMore.value = Boolean(data.value?.links?.next)
  hasLoaded.value = true
  isLoading.value = false
}

loadSessions(true)
watch(filterGameId, () => loadSessions(true))

const sessions = computed(() => loadedSessions.value.map((session) => {
  const attendees = sortBy(attendee => attendee.member.name, session.attendees)
  const winners = attendees.filter(attendee => attendee.winner)
  return {
    ...session,
    attendees,
    winners,
  }
}))

const { isRevealed, reveal, confirm, onConfirm, revealArguments } = compose(
  withArguments(),
  withTiming(),
)(useConfirmDialog())
onConfirm((index: number) => {
  // the next page's offset is the loaded count, so it stays right after removing one
  const [removed] = loadedSessions.value.splice(index, 1)
  useApi('delete', `sessions/${removed.id}`)
})
</script>

<template>
  <div>
    <div class="flex flex-col mb-2">
      <label for="filter-game">{{ t('Game') }}</label>
      <select id="filter-game" v-model="filterGameId" aria-controls="sessions">
        <option value="">
          {{ t('Any') }}
        </option>
        <option v-for="game in games" :key="game.id" :value="game.id">
          {{ game.name }}
        </option>
      </select>
    </div>
    <div v-if="!hasLoaded">
      {{ t('Loading...') }}
    </div>
    <p v-else-if="sessions.length === 0 && filterGameId">
      {{ t('No sessions of this game have been logged yet.') }}
    </p>
    <p v-else-if="sessions.length === 0">
      {{ t('No games have been logged yet.') }}
      <router-link :to="{ name: '/room/[id]/poll', params: route.params }">
        {{ t('Log games in the poll tab') }}
      </router-link>
    </p>
    <ul v-else id="sessions" aria-live="polite" class="remove-list-style">
      <li v-for="(session, index) in sessions" :key="session.id" class="border border-rounded p-2 mb-2">
        <div class="flex justify-end">
          <button
            aria-live="assertive"
            class="icon-btn pl-1"
            @click="() => (isRevealed ? confirm : reveal)(index)"
          >
            <template v-if="isRevealed && revealArguments[0] === index">
              {{ t('Confirm?') }}
            </template>
            <template v-else>
              <i-material-symbols-close-rounded />
              <span class="sr-only">
                {{ t('Delete') }}
              </span>
            </template>
          </button>
        </div>
        <dl>
          <dd>
            <span class="sr-only">{{ t('Game') }}</span>
          </dd>
          <dt>
            <strong class="text-xl">{{ session.game.name }}</strong>
          </dt>
          <dd>
            <i-mdi-clock />
            <span class="sr-only">{{ t('Date') }}</span>
          </dd>
          <dt>{{ formatRelative(new Date(session.inserted_at), new Date) }}</dt>
          <dd>
            <i-mdi-trophy />
            <span class="sr-only">{{ t('Winners') }}</span>
          </dd>
          <dt>
            <template v-if="session.winners.length === session.attendees.length">
              {{ t('Everyone') }}
            </template>
            <template v-else-if="session.winners.length === 0">
              {{ t('Nobody') }}
            </template>
            <template v-else>
              {{ session.winners.map(winner => winner.member.name).join(', ') }}
            </template>
          </dt>
          <dd>
            <i-mdi-users />
            <span class="sr-only">{{ t('Players') }}</span>
          </dd>
          <dt>{{ session.attendees.map(attendee => attendee.member.name).join(', ') }}</dt>
          <template v-if="session.comment">
            <dd>
              <i-mdi-comment />
              <span class="sr-only">{{ t('Comments') }}</span>
            </dd>
            <dt>{{ session.comment }}</dt>
          </template>
        </dl>
      </li>
    </ul>
    <button
      v-if="hasLoaded && hasMore"
      aria-controls="sessions"
      class="w-100%"
      :disabled="isLoading"
      @click="() => loadSessions()"
    >
      {{ isLoading ? t('Loading...') : t('Load more') }}
    </button>
  </div>
</template>

<route lang="yaml">
  meta:
    title: 'History'
</route>

<style scoped>
dl {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
}
dd {
  flex-basis: 10%;
  font-weight: bold;
  text-align: right;
  padding-right: 0.5rem;
}
dd svg {
  margin-left: auto;
}
dt {
  flex-basis: 90%;
}
</style>
