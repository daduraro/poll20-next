<script setup lang="ts">
import { withArguments, withTiming } from '~/composables/confirm'
import { compose } from 'ramda'
import {
  type Game,
  type Member
} from '~/types'

const { t } = useI18n()
const { membership } = useUserStore()
const games = computed(() => membership?.room.games || [])

const editForm = ref({
  title: computed(() => editForm.value.id ? t('Edit game') : t('Create game')),
  id: null as Game['id']|null,
  busy: false,
  value: {
    name: '',
    owners: [] as Member['id'][]
  },
  definition: [
    {
      id: 'name',
      is: 'input',
      attrs: {
        type: 'text',
        required: true
      }
    }
  ],
  reset(game: Partial<Game> = {}) {
    editForm.value.id = null
    editForm.value.value.name = game.name || ''
  },
  edit(game: Game) {
    this.reset(game)
    editForm.value.id = game.id
    nextTick(() => document.querySelector<HTMLInputElement>('#form input')!.focus())
  },
  async submit() {
    editForm.busy = true
    const games = membership!.room.games
    const index = games.findIndex(game => game.id === editForm.value.id)
    if (index !== -1) {
      useApi<Game>('patch', `games/${editForm.value.id}`, { attributes: editForm.value.value })
      games.splice(index, 1, {
        id: games[index].id,
        ...editForm.value.value
      })
    }
    else {
      editForm.value.busy = true
      const { data } = await useApi<Game>('post', `games`, {
        attributes: {
          ...editForm.value.value,
          room_id: membership!.room.id
        }
      })
      editForm.value.busy = false
      games.push({
        id: data.value.entity!.id,
        ...editForm.value.value
      })
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
        <div class="flex">
          <div class="flex-grow text-2xl">
            {{ game.name }}
          </div>
          <button
            v-aria-title="t('Edit {name}', game)"
            class="ml-1 mb-1 btn"
            @click="editForm.id !== game.id
              ? editForm.edit(game)
              : editForm.reset()"
          >
            <i-fa-solid-pencil-alt v-if="editForm.id !== game.id"/>
            <i-fa-solid-arrow-left v-else/>
          </button>
          <button
            v-for="revealed in [isRevealed && revealArguments[0] === game.id]" :key="0"
            aria-controls="games"
            v-aria-title="revealed
              ? t('Confirm?')
              : t('Delete {name}', game)"
            class="ml-1 mb-1 btn btn-danger"
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
    />
  </div>
</template>

<route lang="yaml">
  meta:
    title: 'Games'
</route>