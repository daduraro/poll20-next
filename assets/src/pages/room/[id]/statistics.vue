<script setup lang="ts">
import { compose, groupBy, indexBy, map, sortBy, sum, values } from 'ramda'
import { Game, Member, Session } from '~/types'
import { Bar } from 'vue-chartjs'
import { Chart as ChartJS, Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale } from 'chart.js'
ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale)

const { t } = useI18n()
const { membership } = useUserStore()
const games = computed(() => sortBy(game => game.name.toLowerCase(), membership?.room.games || []))
const gamesById = computed(() => indexBy(game => game.id, games.value))
const membersById = computed(() => indexBy(member => member.id, membership!.room.members))

const { data } = useApi<Session>('get', 'sessions', {
  query: {
    include: ['attendees.member', 'game'],
    sort: '-inserted_at',
  }
})

const filterVisibility = ref({
  games: false,
  players: false,
})

const filters = ref({
  gameIds: [] as Game['id'][],
  memberIds: [] as Member['id'][],
})

function selectViaInput(filter: string[], event: any) {
  if (event.target.value && !filter.includes(event.target.value)) {
    filter.push(event.target.value)
  }
  event.target.value = ''
}

const sessions = computed(() => (data?.value?.entities ?? []))
const filteredSessions = computed(
  () => sessions.value.filter((session: Session) => {
    const { gameIds, memberIds } = filters.value
    return (gameIds.length === 0 || gameIds.some(id => session.game.id === id))
      && (memberIds.length === 0 || memberIds.every(id => session.attendees.find(attendee => attendee.member_id === id)))
  })
)

const chart = computed(() => {
  const limit = 5
  const games = compose(
    sortBy(game => game.count),
    games => games.slice(0, limit),
    games => games.filter((game, index) => index < limit || filters.value.gameIds.includes(game.id)),
    sortBy(game => -game.count),
    values,
    map(sessions => ({ ...sessions[0].game, count: sessions.length })),
    groupBy(session => session.game.id.toString())
  )(filteredSessions.value)

  const total = sum(games.map(game => game.count))
  const style = getComputedStyle(document.body)
  const gridStyle = {
    color: style.getPropertyValue('--border-color'),
    borderColor: style.getPropertyValue('--border-color'),
  }
  return {
    component: Bar,
    title: 'Most played',
    data: {
      labels: games.map(game => game.name),
      datasets: [
        {
          label: t('Times played'),
          data: games.map(game => game.count),
          backgroundColor: style.getPropertyValue('--main-color')
        }
      ]
    },
    options: {
      responsive: true,
      scales: {
        x: {
          grid: gridStyle,
        },
        y: {
          grid: gridStyle,
          ticks: {
            precision: 0,
          },
        },
      },
      plugins: {
        tooltip: {
          callbacks: {
            label: function (context: any) {
              let label = context.dataset.label || '';
              const shownPercentage = (100 * context.parsed.y / total).toFixed(2)
              const allPercentage = (100 * context.parsed.y / sessions.value.length).toFixed(0)
              return `${label}: ${context.parsed.y} (${shownPercentage}% of shown, ${allPercentage}% of total)`;
            },
          },
        }
      },
    },
  }
})

</script>

<template>
  <div v-if="!data">
    {{ t('Loading...') }}
  </div>
  <div>
    <div class="flex justify-end">
      <span class="flex-grow" />
      <button aria-controls="filters-games" v-aria-title="t('Toggle games filter')"
        class="icon-btn border border-rounded p-2 display-block" :class="{ active: filterVisibility.games, 'mr-2': true }"
        @click="filterVisibility.games = !filterVisibility.games">
        <i-fa-gamepad />
      </button>
      <button aria-controls="filters-players" v-aria-title="t('Toggle players filter')"
        class="icon-btn border border-rounded p-2 display-block" :class="{ active: filterVisibility.players }"
        @click="filterVisibility.players = !filterVisibility.players">
        <i-fa-user />
      </button>
    </div>
    <div id="filters-games" v-show="filterVisibility.games" class="p-2 border-rounded mt-2 border">
      <!-- options -->
      <div class="options">
        <label for="filter-games" class="flex">
          {{ t('Only include these games:') }}
        </label>
        <select id="filter-games" @input="selectViaInput(filters.gameIds, $event)">
          <option value="">{{ t('Choose game') }}</option>
          <option v-for="game in games" :key="game.id" :value="game.id">
            {{ game.name }}
          </option>
        </select>
        <ul>
          <li v-for="(id, index) in filters.gameIds" :key="id" class="mt-2">
            <button class="btn btn-danger" @click="filters.gameIds.splice(index, 1)">
              <i-fa-solid-times />
              <span class="sr-only">
                {{ t('Remove {name} from filter', gamesById[id]) }}
              </span>
            </button>
            {{ gamesById[id].name }}
          </li>
        </ul>
      </div>
    </div>
    <div id="filters-players" v-show="filterVisibility.players" class="p-2 border-rounded mt-2 border">
      <!-- options -->
      <div class="options">
        <label for="filter-players" class="flex">
          {{ t('Only include these members:') }}
        </label>
        <select id="filter-players" @input="selectViaInput(filters.memberIds, $event)">
          <option value="">{{ t('Choose member') }}</option>
          <option v-for="member in membership!.room.members" :key="member.id" :value="member.id">
            {{ member.name }}
          </option>
        </select>
        <ul>
          <li v-for="(id, index) in filters.memberIds" :key="id" class="mt-2">
            <button class="btn btn-danger" @click="filters.memberIds.splice(index, 1)">
              <i-fa-solid-times />
              <span class="sr-only">
                {{ t('Remove {name} from filter', membersById[id]) }}
              </span>
            </button>
            {{ membersById[id].name }}
          </li>
        </ul>
      </div>
    </div>
    <component :is="chart.component" v-bind="chart" />
  </div>
</template>

<route lang="yaml">
  meta:
    title: 'Statistics'
</route>