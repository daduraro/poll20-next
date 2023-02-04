<script setup lang="ts">
import { withArguments, withTiming } from '~/composables/confirm'
import { compose, range } from 'ramda'
import {
  type Game,
  type Member
} from '~/types'

const { t } = useI18n()
const { membership } = useUserStore()
const games = computed(() => membership?.room.games || [])

const playerNumberOptions = range(1, 21)

const editForm = ref({
  title: computed(() => editForm.value.id ? t('Edit game') : t('Add game')),
  id: null as Game['id']|null,
  busy: false,
  value: {
    name: '',
    owners: [] as Member['id'][],
    players_max: null,
  },
  definition: [
    {
      id: 'name',
      label: t('Name'),
      is: 'input',
      attrs: {
        type: 'text',
        required: true
      }
    },
    {
      id: 'players_max',
      label: t('Max number of players')
    },
    {
      id: 'owners',
    },
  ],
  reset(game: Partial<Game> = {}) {
    editForm.value.id = null
    editForm.value.value.name = game.name || ''
    editForm.value.value.owners = game.owners?.map(owner => owner.id) || []
    editForm.value.value.players_max = game.players_max || null
  },
  edit(game: Game) {
    this.reset(game)
    editForm.value.id = game.id
    nextTick(() => document.querySelector<HTMLInputElement>('#form input')!.focus())
  },
  async submit() {
    editForm.busy = true
    const attributes = { ...editForm.value.value }
    const patch = {
        ...attributes,
        owners: editForm.value.value.owners.map(id => ({ id }))
    }

    // api complains about nulls
    attributes.players_max = attributes.players_max ?? ""

    const games = membership!.room.games
    const index = games.findIndex(game => game.id === editForm.value.id)
    if (index !== -1) {
      useApi<Game>('patch', `games/${editForm.value.id}`, { attributes })
      games.splice(index, 1, { id: games[index].id, ...patch })
    }
    else {
      editForm.value.busy = true
      const { data } = await useApi<Game>('post', `games`, {
        attributes: {
          ...attributes,
          room_id: membership!.room.id
        }
      })
      editForm.value.busy = false
      games.push({ id: data.value.entity!.id, ...patch })
    }
    editForm.value.reset()
  },
})

const refGames = ref<HTMLUListElement|null>(null)
const { reveal, revealArguments, isRevealed, confirm, onConfirm } = compose(
  withTiming(),
  withArguments()
)(useConfirmDialog())
onConfirm((id: Game['id']) => {
  useApi<Game>('delete', `games/${id}`)
  membership!.room.games.splice(
    membership!.room.games.findIndex(item => item.id === id), 1
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
      ref="refGames"
      id="games"
      tabindex="-1"
      :aria-label="t('Games')"
    >
      <li v-for="game in games" :key="game.id">
        <div class="flex mb-2">
          <button
            v-for="revealed in [isRevealed && revealArguments[0] === game.id]" :key="0"
            aria-controls="games"
            v-aria-title="revealed
              ? t('Confirm?')
              : t('Delete {name}', game)"
            class="mr-2 btn btn-danger"
            @click="() => revealed
              ? confirm(game.id)
              : reveal(game.id)"
          >
            <template v-if="revealed">
              {{ t('Confirm?') }}
            </template>
            <template v-else>
              <i-fa-solid-times/>
              <span class="sr-only">
                {{ t('Delete {name}', game) }}
              </span>
            </template>
          </button>
          <button
            v-aria-title="t('Edit {name}', game)"
            class="mr-2 btn"
            @click="editForm.id !== game.id
              ? editForm.edit(game)
              : editForm.reset()"
          >
            <i-fa-solid-pencil-alt v-if="editForm.id !== game.id"/>
            <i-fa-solid-arrow-left v-else/>
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
          <option :value="null">{{ t('Any') }}</option>
          <option v-for="number in playerNumberOptions" :key="number" :value="number">{{ number }}</option>
        </select>
      </template>
      <template #owners>
        <fieldset>
          <legend>{{ t('Game owners') }}</legend>
          <div v-for="member in membership!.room.members" :key="member.id" class="flex">
            <input :id="`member-${member.id}`" type="checkbox" v-model="editForm.value.owners" name="owner" :value="member.id" class="m-2">
            <label :for="`member-${member.id}`">{{ member.name }}</label>
          </div>
        </fieldset>
      </template>
    </PForm>
  </div>
</template>

<route lang="yaml">
  meta:
    title: 'Games'
</route>