<script setup lang="ts">
import seedrandom from 'seedrandom'
import { type Vote } from '~/types/vote'
import { sortByTiered } from '~/lib/utils/array'
import { equals, fromPairs, groupBy, indexBy, prop, sortBy } from 'ramda';
import { Game, Member } from '~/types';

const route = useRoute()
const filters = useLocalStorage(`${route.path}.filters`, {
  onlyPresentVotes: true,
  onlyPresentGames: true,
  activeMemberIds: [] as Member['id'][],
})
const filtersVisible = ref(false)
const presenceVisible = ref(true)

const { t } = useI18n()
const { membership } = useUserStore()

const members = computed(() => membership!.room.members)
const membersSorted = computed(() => sortBy(prop('name'), members.value))
const membersById = computed(() => indexBy(prop('id'), members.value))
const membersActive = computed(
  () => filters.value.activeMemberIds.length > 0 // ignore filter if none checked
    ? members.value.filter(member => filters.value.activeMemberIds.some(equals(member.id)))
    : members.value
)
const activeMemberIds = computed(() => new Set(membersActive.value.map(member => member.id)))

const games = computed(() => membership!.room.games)
const gamesActive = computed(
  () => filters.value.onlyPresentGames
    ? games.value.filter(game =>
        game.owners.length === 0 || // skip games with no ownership info
        game.owners.some(member => activeMemberIds.value.has(member.id))
      )
    : games.value
)
const openedGameIds = ref<Set<Game['id']>>(new Set())

const votes = ref<Vote[]>([])
const votesVisible = computed<Vote & {active: boolean}>(
  () => sortByTiered(
    vote => [
      // first active, then newest
      vote.active ? -1 : 1,
      vote.created_at,
    ],
    votes.value.map(vote => ({
      ...vote,
      active: activeMemberIds.value.has(vote.member_id)
    }))
  )
)
const votesByGame = computed(() => groupBy(prop('game_id'), votesVisible.value))
const votesOwn = computed(() => votes.value.filter(vote => vote.member_id === membership!.member_id))
const votesOwnByGame = computed(() => indexBy(prop('game_id'), votesOwn.value))
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
      -(scoresByGame.value[game.id][1] - scoresByGame.value[game.id][-1]),
      game.tiebreaker
  ], gamesActive.value.map(game => ({
    ...game,
    tiebreaker: randomGenerator()
  })))
})

function vote(game_id: Game['id'], value: Vote['value']|undefined) {
  const member_id = membership!.member_id
  const current = votes.value.find(vote => vote.member_id === member_id && vote.game_id === game_id)
  if (current && value === undefined) {
    votes.value.splice(votes.value.indexOf(current), 1)
  }
  else if (current) {
    current.value = value
  }
  else if (value !== undefined) {
    votes.value.push({ game_id, member_id, value})
  }
}
</script>

<template>
  <div>
    <div class="flex">
      <span class="flex-grow"/>
      <button
        aria-controls="filters"
        v-aria-title="t('Toggle filters')"
        class="icon-btn border border-rounded p-2 display-block mr-2"
        :class="{ active: filtersVisible }"
        @click="filtersVisible = !filtersVisible"
      >
        <i-fa-cog />
      </button>
      <button
        aria-controls="presence"
        v-aria-title="t('Toggle presence options')"
        :class="{ active: presenceVisible }"
        class="icon-btn border border-rounded p-2 display-block"
        @click="presenceVisible = !presenceVisible"
      >
        <i-fa-group />
      </button>
    </div>
    <div
      id="presence"
      v-show="presenceVisible"
      aria-controls="games"
      class="p-2 border-rounded mt-2 border"
    >
      <!-- presence -->
      <label class="flex justify-end pl-4">
        <strong>{{ t('Presence') }}</strong>
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
      <ul class="remove-list-style">
        <li v-for="member in membersSorted" :key="member.id">
          <label class="flex justify-end">
            {{ member.name }}
            <input
              type="checkbox"
              v-model="filters.activeMemberIds"
              :value="member.id"
              class="ml-2"
            >
          </label>
        </li>
      </ul>
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
        class="border border-rounded p-3 ml-0 my-2 mb-4 cursor-pointer"
        @click="() => openedGameIds.has(game.id) ? openedGameIds.delete(game.id) : openedGameIds.add(game.id)"
      >
        <div class="flex">
          <div class="flex-grow">
            <div class="flex flex-col items-start">
              <div class="flex-grow text-xl">{{ game.name }}</div>
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
              @click.stop="() => vote(game.id, votesOwnByGame[game.id]?.value === 1 ? undefined : 1)"
            >
              <i-fa-arrow-up :class="{'vote-up': votesOwnByGame[game.id]?.value === 1 }"/>
            </button>
            <button
              v-aria-title="t('Vote down')"
              :class="{ active: votesOwnByGame[game.id]?.value === -1 }"
              class="icon-btn"
              @click.stop="() => vote(game.id, votesOwnByGame[game.id]?.value === -1 ? undefined : -1)"
            >
              <i-fa-arrow-down :class="{'vote-down': votesOwnByGame[game.id]?.value === -1 }"/>
            </button>
          </div>
        </div>
        <div
          aria-live="polite"
          :aria-label="t('Votes')"
          :class="{ hidden: !openedGameIds.has(game.id) }"
        >
          <hr>
          <p v-if="!votesByGame[game.id]?.length">No votes</p>
          <ul class="mt-2" style="list-style: initial">
            <li v-for="vote in votesByGame[game.id]" :key="vote.id" class="vote" :class="{ present: !filters.onlyPresentVotes || activeMemberIds.has(vote.member_id) }">
              <div class="flex items">
                <div class="mr-2">
                  {{ membersById[vote.member_id].name }}
                </div>
                <div class="text-sm">
                  <i-fa-arrow-up v-if="vote.value > 0" class="icon-bt vote-up mt-0" style="font-weight: 300"/>
                  <i-fa-arrow-down v-else  class="icon-btn mt-0 vote-down" style="font-weight: 300"/>
                </div>
              </div>
            </li>
          </ul>
        </div>
      </li>
    </TransitionGroup>
  </div>
</template>

<route lang="yaml">
  meta:
    title: 'Vote'
</route>

<style scoped>
.vote-up {
  color: var(--danger);
}

.vote-down {
  color: var(--blue);
}
.vote:not(.present) {
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