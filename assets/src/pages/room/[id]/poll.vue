<script setup lang="ts">
import seedrandom from 'seedrandom'
import { type Vote } from '~/types/vote'
import { sortByTiered } from '~/lib/utils/array'
import { equals, fromPairs, groupBy, indexBy, prop, sortBy } from 'ramda';
import { startOfDay } from 'date-fns'
import { Game, Member, Session, Attendee } from '~/types';

const route = useRoute()
const filters = useLocalStorage(`${route.path}.filters`, {
  onlyPresentVotes: true,
  onlyPresentGames: true,
  playersInRange: true,
  activeMemberIds: [] as Member['id'][],
}, {
  mergeDefaults: true
})
const filtersVisible = ref(false)

const { t } = useI18n()
const { membership } = useUserStore()

const members = computed(() => membership?.room.members ?? [])
const membersSorted = computed(() => sortBy(prop('name'), members.value))
const membersById = computed(() => indexBy(prop('id'), members.value))
const membersActive = computed(
  () => filters.value.activeMemberIds.length > 0 // ignore filter if none checked
    ? members.value.filter(member => filters.value.activeMemberIds.some(equals(member.id)))
    : members.value
)
const activeMemberIds = computed(() => new Set(membersActive.value.map(member => member.id)))

const games = computed(() => membership?.room.games ?? [])
const gamesById = computed(() => indexBy(prop('id'), games.value))
const gamesActive = computed(
  () => games.value.filter(game => {
    if (filters.value.onlyPresentGames && game.owners.length > 0) {
      const presentOwners = game.owners.filter(owner => activeMemberIds.value.has(owner.id))
      const exactlyAllPresent = game.owners.length === presentOwners.length && presentOwners.length === membersActive.value.length
      if (!game.match_all_owners && presentOwners.length === 0) {
        return false
      }
      else if (game.match_all_owners && !exactlyAllPresent) {
        return false
      }
    }

    if (
      filters.value.playersInRange
      && game.players_max !== null
      && game.players_max < membersActive.value.length
    ) {
      return false
    }

    return true
  })
)
const gamesFilteredCount = computed(() => games.value.length - gamesActive.value.length)
const openedGameIds = ref<Set<Game['id']>>(new Set())

const votes = ref<Vote[]>([])
const votesVisible = computed<Vote & {active: boolean}>(
  () => sortByTiered(
    vote => [
      // first active, then newest
      vote.active ? -1 : 1,
      vote.inserted_at,
    ],
    votes.value.map(vote => ({
      ...vote,
      active: activeMemberIds.value.has(vote.member_id)
    }))
  )
)
const votesByGame = computed(() => ({
  ...fromPairs(games.value.map(game => [game.id, []])),
  ...groupBy(prop('game_id'), votesVisible.value)
}))
const votesOwn = computed(() => votes.value.filter(vote => vote.member_id === membership?.member_id))
const votesOwnByGame = computed(() => ({
  ...fromPairs(games.value.map(game => [game.id, []])),
  ...indexBy(prop('game_id'), votesOwn.value)
}))
const votesActive = computed(
  () => filters.value.onlyPresentVotes
    ? votes.value.filter(vote => membersActive.value.some(item => item.id === vote.member_id))
    : votes.value
)

const scoresByGame = computed(
  () => votesActive.value.reduce(
    (scores, vote) => {
      scores[vote.game_id][vote.value] += 1
      return scores
    },
    fromPairs(games.value.map(game => [
      game.id,
      {
        [-1]: 0,
        [+1]: 0,
      }
    ]))
  )
)

const gamesSorted = computed(() => {
  // ensure all members see the same sort result when votes are tied
  const randomGenerator = seedrandom((new Date).getDate())
  return sortByTiered(game => [
      -(scoresByGame.value[game.id][1] - scoresByGame.value[game.id][-1]), // first by score
      scoresByGame.value[game.id][-1], // then by least downvotes
      game.tiebreaker, // then by static random factor
  ], gamesActive.value.map(game => ({
    ...game,
    tiebreaker: randomGenerator()
  })))
})

let refreshRate = 10000
let refreshHandle: any
const isFetching = ref(false)
async function fetchVotes(manual = false) {
  refreshHandle && clearTimeout(refreshHandle)
  isFetching.value = true
  const { data } = await useApi<Vote[]>('get', 'votes', { query: { include: 'member' }})
  const newVotes = data.value.entities!
  membership!.room.members = membership!.room.members.concat(newVotes
    .filter(vote => !members.value.some(member => member.id === vote.member_id))
    .map(vote => vote.member))
  
  votes.value = data.value.entities!
  isFetching.value = false
  refreshHandle = setTimeout(fetchVotes, refreshRate)
  if (!manual) {
    refreshRate *= 1.5 // decay rate over time
  }
}

fetchVotes()
onBeforeUnmount(() => {
  refreshHandle && clearTimeout(refreshHandle)
})

// Delays next tick of vote fetching.
// Useful to avoid that tick overriding the temporary local state
function throttleVotes() {
  refreshHandle && clearTimeout(refreshHandle)
  refreshHandle = setTimeout(fetchVotes, refreshRate)
}

async function vote(game_id: Game['id'], value: Vote['value']|undefined) {
  throttleVotes()

  const member_id = membership!.member_id
  const current = votes.value.find(vote => vote.member_id === member_id && vote.game_id === game_id)
  if (current && !current.id) {
    await current.handle // wait before attempting to operate on new items to quick
  }

  if (current && value === undefined) {
    votes.value.splice(votes.value.indexOf(current), 1)
    useApi<Vote>('delete', `votes/${current.id}`)
  }
  else if (current) {
    current.value = value
    useApi<Vote>('patch', `votes/${current.id}`, { attributes: { value }})
  }
  else if (value !== undefined) {
    const attributes =  { game_id, member_id, value }
    const localVote: any = { ...attributes, id: null, inserted_at: (new Date).toISOString(), handle: null }
    votes.value.push(localVote)
    localVote.handle = useApi<Vote>('post', 'votes', { attributes })
    localVote.handle.then(({ data }: any) => localVote.id = data.value.entity!.id)
  }
}

const loggedGameId = ref<Game['id']|null>(null)
const sessionGameId = ref<Game['id']|null>(null)
const sessionValue = ref({
  attendees: [] as Attendee[],
  comment: '',
})
const sessionFormTitle = computed(() => sessionGameId.value ? t('Log session of {name}', gamesById.value[sessionGameId.value]) : '')
const sessionFormDefinition = [
  {
    id: 'attendees',
    label: t('Winners'),
  },
  {
    id: 'comment',
    label: t('Comments'),
    is: 'textarea'
  },
]
function logSession(game_id: Game['id']) {
  sessionGameId.value = game_id
  sessionValue.value.attendees = membersActive.value.map(member => ({
    member_id: member.id,
    winner: false,
    name: member.name,
    vote: votesByGame.value[game_id].find(vote => vote.member_id === member.id)?.value ?? null,
  }))
}
const isSavingSession = ref(false)
async function saveSession() {
  isSavingSession.value = true
  await useApi<Session>('post', 'sessions', {
    attributes: {
      game_id: sessionGameId.value,
      attendees: sessionValue.value.attendees,
      comment: sessionValue.value.comment
    }
  })
  loggedGameId.value = sessionGameId.value
  setTimeout(() => loggedGameId.value = null, 3000)
  sessionGameId.value = null
  isSavingSession.value = false
}
</script>

<template>
  <div>
    <div
      id="presence"
      aria-controls="games"
      class="my-2"
    >
      <!-- presence -->
      <div class="flex items-end">
        {{ t('Presence') }}
        <span class="flex-grow"/>
        <label class="pr-1">
          <strong>{{ t('Select all') }}</strong>
          <input
            type="checkbox"
            :checked="filters.activeMemberIds.length === members.length"
            :indeterminate="filters.activeMemberIds.length > 0 && filters.activeMemberIds.length < members.length"
            class="ml-2"
            @input="() => filters.activeMemberIds.length < members.length
              ? filters.activeMemberIds = members.map(member => member.id)
              : filters.activeMemberIds =  []"
          >
        </label>
      </div>
      <ul class="remove-list-style">
        <li v-for="member in membersSorted" :key="member.id">
          <label
            v-for="checked in [filters.activeMemberIds.some(id => id === member.id)]" key="0"
            tabindex="0"
            aria-role="checkbox"
            :aria-checked="checked ? 'true' : 'false'"
            class="flex pl-2! label-checkbox"
          >
            <i-material-symbols-check-box v-if="checked" class="mr-2"/>
            <i-material-symbols-check-box-outline-blank v-else class="mr-2"/>
            {{ member.name }}
            <input
              tabindex="-1"
              type="checkbox"
              v-model="filters.activeMemberIds"
              :value="member.id"
              class="ml-2"
            >
          </label>
        </li>
      </ul>
    </div>
    <div class="flex justify-end">
      <i v-if="gamesFilteredCount > 0" class="mr-2">
        {{ t('{count} games filtered out', { count: gamesFilteredCount }) }}
      </i>
      <span class="flex-grow"/>
      <button
        aria-controls="games"
        v-aria-title="t('Refresh votes')"
        class="icon-btn border border-rounded p-2 display-block mr-2"
        :disabled="isFetching"
        @click="() => fetchVotes()"
      >
        <i-fa-refresh :class="{ 'animate-spin preserve-3d': isFetching} "/>
      </button>
      <button
        aria-controls="filters"
        v-aria-title="t('Toggle filters')"
        class="icon-btn border border-rounded p-2 display-block"
        :class="{ active: filtersVisible }"
        @click="filtersVisible = !filtersVisible"
      >
        <i-fa-cog />
      </button>
    </div>
    <div
      id="filters"
      v-show="filtersVisible"
      aria-controls="games"
      class="p-2 border-rounded mt-2 border"
    >
      <!-- options -->
      <div class="options">
        <label class="flex">
          <input type="checkbox" v-model="filters.onlyPresentVotes" :value="true" class="mr-2"> {{ t('Only count votes of present members') }}
        </label>
        <label class="flex">
          <input type="checkbox" v-model="filters.onlyPresentGames" :value="true" class="mr-2"> {{ t('Only show games of present members') }}
        </label>
        <label class="flex">
          <input type="checkbox" v-model="filters.playersInRange" :value="true" class="mr-2"> {{ t('Filter by max number of players of the game') }}
        </label>
      </div>
    </div>
    <TransitionGroup
      name="list"
      tag="ul"
      id="games"
      aria-live="polite"
      class="remove-list-style"
    >
      <li
        v-for="game in gamesSorted" :key="game.id"
        :id="game.id"
        :aria-controls="game.id"
        :aria-label="t('Toggle list of votes')"
        class="border border-rounded p-3 ml-0 my-2 mb-4"
      >
        <div class="flex">
          <div class="flex-grow">
            <div 
              tabindex="0"
              aria-role="button"
              class="flex flex-col items-stretch"
              @click="() => openedGameIds.has(game.id) ? openedGameIds.delete(game.id) : openedGameIds.add(game.id)"
            >
              <div class="text-xl">
                {{ game.name }}
              </div>
              <div class="flex mt-2">
                <span class="mr-2 flex">
                   {{ scoresByGame[game.id][1] }} <i-fa-arrow-up class="vote-up display-inline text-xs ml-1"/>
                </span>
                <span class="flex ml-1">
                   {{ scoresByGame[game.id][-1] }} <i-fa-arrow-down class="vote-down display-inline text-xs ml-1"/>
                </span>
              </div>
            </div>
          </div>
          <div class="flex flex-col">
            <button
              v-aria-title="t('Vote up')"
              :class="{ active: votesOwnByGame[game.id]?.value === 1 }"
              class="icon-btn mb-4"
              @click="() => vote(game.id, votesOwnByGame[game.id]?.value === 1 ? undefined : 1)"
            >
              <i-fa-arrow-up :class="{'vote-up': votesOwnByGame[game.id]?.value === 1 }"/>
            </button>
            <button
              v-aria-title="t('Vote down')"
              :class="{ active: votesOwnByGame[game.id].value === -1 }"
              class="icon-btn"
              @click="() => vote(game.id, votesOwnByGame[game.id].value === -1 ? undefined : -1)"
            >
              <i-fa-arrow-down :class="{'vote-down': votesOwnByGame[game.id].value === -1 }"/>
            </button>
          </div>
        </div>
        <div
          aria-live="polite"
          :aria-label="t('Votes')"
          :class="{ hidden: !openedGameIds.has(game.id) }"
        >
          <hr>
          <p v-if="!votesByGame[game.id].length">No votes</p>
          <ul class="mt-0! ml-0!" style="list-style: initial">
            <li
              v-for="vote in votesByGame[game.id]" :key="vote.id"
              :class="{ present: !filters.onlyPresentVotes || activeMemberIds.has(vote.member_id) }"
              class="game-vote flex mt-1"
            >
              <div class="text-sm">
                <i-fa-arrow-up v-if="vote.value > 0" class="icon-bt vote-up mt-0" style="font-weight: 300"/>
                <i-fa-arrow-down v-else  class="icon-btn mt-0 vote-down" style="font-weight: 300"/>
              </div>
              <div class="ml-1">
                {{ membersById[vote.member_id].name }}
              </div>
            </li>
          </ul>
          <button
            :aria-controls="`session-${game.id}`"
            class="w-100% mt-3"
            @click="logSession(game.id)"
          >
            {{ t('Log session') }}
          </button>
          <div v-if="loggedGameId === game.id">
            {{ t('Logged successfully') }}
          </div>
          <div
            :id="`session-${game.id}`"
            v-show="sessionGameId === game.id"
          >
            <p-form
              v-if="sessionGameId === game.id"
              v-model:value="sessionValue"
              :title="sessionFormTitle"
              :definition="sessionFormDefinition"
              :busy="isSavingSession"
              class="mt-2"
              @submit="saveSession"
            >
              <template #attendees>
                <ul>
                  <li v-for="attendee in sessionValue.attendees" :key="attendee.member_id">
                    <label>
                      <input type="checkbox" v-model="attendee.winner"> {{ attendee.name }}
                    </label>
                  </li>
                </ul>
              </template>
            </p-form>
          </div>
        </div>
      </li>
    </TransitionGroup>
  </div>
</template>

<route lang="yaml">
  meta:
    title: 'Poll'
</route>

<style scoped>
.vote-up {
  color: var(--danger);
}

.label-checkbox {
  border: 1px solid var(--border-color);
  padding: 0.25rem;
  border-radius: 10px;
  margin-top: 0.5rem;
  cursor: pointer;
}

.label-checkbox[aria-checked="true"] {
  border-color: transparent;
  background-color: var(--main-color);
  color: var(--main-color-contrast);
}
.label-checkbox > input {
  opacity: 0.01;
  width: 1px;
  height: 1px;
}

.vote-down {
  color: var(--blue);
}
.vote:not(.present) {
  opacity: 50%;
}

.game-vote:not(.present) {
  opacity: 50%;
}

:deep(.list-move),
:deep(.list-enter-active) {
  transition: transform 0.5s ease;
}

:deep(.list-enter-from),
:deep(.list-leave-to) {
  opacity: 0;
}
</style>