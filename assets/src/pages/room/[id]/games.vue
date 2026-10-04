<script setup lang="ts">
import type { Game, Member } from '~/types'
import { range, sortBy } from 'ramda'
import { withArguments, withTiming } from '~/composables/confirm'

const { t } = useI18n()
const { membership } = useUserStore()
const games = computed(() => membership?.room.games || [])
const gamesSorted = computed(() => sortBy(game => game.name.toLowerCase(), games.value))

const playerNumberOptions = range(1, 21)

const editForm = ref({
  title: computed((): string => editForm.value.id ? t('Edit game') : t('Add game')),
  id: null as Game['id'] | null,
  busy: false,
  value: {
    name: '',
    owners: [] as Member['id'][],
    players_max: null as number | null,
    match_all_owners: false,
  },
  definition: [
    {
      id: 'name',
      label: t('Name'),
      is: 'input',
      attrs: {
        type: 'text',
        required: true,
      },
    },
    {
      id: 'players_max',
      label: t('Max number of players'),
    },
    {
      id: 'owners',
    },
    {
      id: 'match_all_owners',
      label: t('Match all owners'),
    },
  ],
  reset(game: Partial<Game> = {}) {
    editForm.value.id = null
    editForm.value.value.name = game.name || ''
    editForm.value.value.owners = game.owners?.map(owner => owner.id) || []
    editForm.value.value.players_max = game.players_max || null
    editForm.value.value.match_all_owners = game.match_all_owners || false
  },
  edit(game: Game) {
    this.reset(game)
    editForm.value.id = game.id
    nextTick(() => document.querySelector<HTMLInputElement>('#form input')!.focus())
  },
  async submit() {
    const patch = {
      ...editForm.value.value,
      owners: membership!.room.members.filter(member => editForm.value.value.owners.includes(member.id)),
    }

    // api complains about nulls
    const attributes = {
      ...editForm.value.value,
      players_max: editForm.value.value.players_max ?? '',
    }

    const games = membership!.room.games
    const index = games.findIndex(game => game.id === editForm.value.id)
    if (index !== -1) {
      useApi<Game>('patch', `games/${editForm.value.id}`, { attributes })
      games.splice(index, 1, { ...games[index], ...patch })
    }
    else {
      editForm.value.busy = true
      const { data } = await useApi<Game>('post', `games`, {
        attributes: {
          ...attributes,
          room_id: membership!.room.id,
        },
      })
      editForm.value.busy = false
      // the response has every attribute but not the owners relationship nor the aggregates
      games.push({ ...data.value!.entity!, owners: patch.owners, last_played_at: null })
    }
    editForm.value.reset()
  },
})

const refGames = ref<HTMLUListElement | null>(null)
const { reveal, revealArguments, isRevealed, confirm, onConfirm } = withTiming()(withArguments()(useConfirmDialog()))
onConfirm((id: Game['id']) => {
  useApi<Game>('delete', `games/${id}`)
  membership!.room.games.splice(
    membership!.room.games.findIndex(item => item.id === id),
    1,
  )
  nextTick(() => refGames.value!.focus())
})
</script>

<template>
  <div>
    <p v-if="games.length === 0">
      {{ t('You haven\'t defined any games yet') }}
    </p>
    <ul
      id="games"
      ref="refGames"
      tabindex="-1"
      :aria-label="t('Games')"
    >
      <li v-for="game in gamesSorted" :key="game.id">
        <div class="flex mb-2">
          <!-- single-item v-for to name a local value; constant key keeps the element (and focus) -->
          <!-- eslint-disable vue/valid-v-for -->
          <button
            v-for="revealed in [isRevealed && revealArguments[0] === game.id]" :key="0"
            v-aria-title="revealed
              ? t('Confirm?')
              : t('Delete {name}', game)"
            aria-controls="games"
            class="mr-2 btn btn-danger"
            @click="() => revealed
              ? confirm(game.id)
              : reveal(game.id)"
          >
            <template v-if="revealed">
              {{ t('Confirm?') }}
            </template>
            <template v-else>
              <i-fa-solid-times />
              <span class="sr-only">
                {{ t('Delete {name}', game) }}
              </span>
            </template>
          </button>
          <!-- eslint-enable vue/valid-v-for -->
          <button
            v-aria-title="t('Edit {name}', game)"
            class="mr-2 btn"
            @click="editForm.id !== game.id
              ? editForm.edit(game)
              : editForm.reset()"
          >
            <i-fa-solid-pencil-alt v-if="editForm.id !== game.id" />
            <i-fa-solid-arrow-left v-else />
          </button>
          <div class="flex-grow text-2xl">
            {{ game.name }}
          </div>
        </div>
      </li>
    </ul>

    <PForm
      id="form"
      v-model:value="editForm.value"
      :title="editForm.title"
      :definition="editForm.definition"
      :busy="editForm.busy"
      @submit="editForm.submit"
    >
      <template #players_max>
        <select v-model="editForm.value.players_max">
          <option :value="null">
            {{ t('Any') }}
          </option>
          <option v-for="number in playerNumberOptions" :key="number" :value="number">
            {{ number }}
          </option>
        </select>
      </template>
      <template #owners>
        <fieldset>
          <legend>{{ t('Game owners') }}</legend>
          <div v-for="member in membership!.room.members" :key="member.id" class="flex">
            <input :id="`member-${member.id}`" v-model="editForm.value.owners" type="checkbox" name="owner" :value="member.id" class="m-2">
            <label :for="`member-${member.id}`">{{ member.name }}</label>
          </div>
        </fieldset>
      </template>
      <template #match_all_owners>
        <label style="font-weight: normal">
          <input
            v-model="editForm.value.match_all_owners"
            type="checkbox"
            aria-describedby="match_all_owners-description"
          > {{ t('Make the game available only if the list of present players exactly matches the list of owners. Useful for role-playing campaigns.') }}
        </label>
      </template>
    </PForm>
  </div>
</template>

<route lang="yaml">
  meta:
    title: 'Games'
</route>
