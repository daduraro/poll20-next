<script setup lang="ts">
import { formatRelative } from 'date-fns'
import { compose, sortBy } from 'ramda'
import { Session } from '~/types'

const route = useRoute()
const { t } = useI18n()
const { data } = useApi<Session>('get', 'sessions', {
  query: {
    include: ['attendees.member', 'game'],
    sort: '-inserted_at',
  }
})

const sessions = computed(() => (data?.value.entities ?? []).map(session => {
  const attendees = sortBy(attendee => attendee.member.name, session.attendees)
  const winners = attendees.filter(attendee => attendee.winner)
  return {
    ...session,
    attendees,
    winners
  }
}))

const { isRevealed, reveal, confirm, onConfirm, revealArguments } = compose(
  withArguments(),
  withTiming(),
)(useConfirmDialog())
onConfirm((index: number) => {
  const [removed] = data.value.entities.splice(index, 1)
  triggerRef(data.value) // otherwise it doesn't pick it up because it's a shallowRef
  useApi('delete', `sessions/${removed.id}`)
})
</script>

<template>
  <div v-if="!data">
    {{ t('Loading...') }}
  </div>
  <p v-else-if="sessions.length === 0">
    {{ t('No games have been logged yet.') }}
    <router-link :to="{ name: 'room-id-poll', params: route.params }">
      {{ t('Log games in the poll tab') }}
    </router-link>
  </p>
  <ul v-else class="remove-list-style">
    <li v-for="(session, index) in sessions" class="border border-rounded p-2 mb-2">
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
          <i-mdi-clock/>
          <span class="sr-only">{{ t('Date') }}</span>
        </dd>
        <dt>{{ formatRelative(new Date(session.inserted_at), new Date) }}</dt>
        <dd>
          <i-mdi-trophy/>
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
          <i-mdi-users/>
          <span class="sr-only">{{ t('Players') }}</span>
        </dd>
        <dt>{{ session.attendees.map(attendee => attendee.member.name).join(', ') }}</dt>
        <template v-if="session.comment">
          <dd>
            <i-mdi-comment/>
            <span class="sr-only">{{ t('Comments') }}</span>
          </dd>
          <dt>{{ session.comment }}</dt>
        </template>
      </dl>
    </li>
  </ul>
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