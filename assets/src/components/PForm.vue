<script setup lang="ts">
import { PropType } from 'vue'

const { t } = useI18n()

const props = defineProps({
  definition: {
    type: Array as PropType<{
      id: string;
      label: string;
      is: string;
      attrs: Record<string, any>;
    }[]>,
    required: true
  },
  value: {
    type: Object as PropType<object>,
    required: true,
  },
  title: String,
  submitLabel: String,
  busy: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['submit', 'update:value'])
</script>

<template>
  <form
    :aria-label="title"
    :aria-busy="busy"
    @submit.prevent="emit('submit')"
  >
    <h2 class="text-xl text-center">{{ title }}</h2>
    <div
      v-for="field in props.definition"
      :key="field.id"
      class="form-field"
    >
      <label :for="field.id" class="mr-2 mb-0">
        {{ field.label }}
      </label>
      <slot :name="field.id" v-bind="field">
        <component
          :is="field.is"
          :id="field.id"
          :value="value[field.id]"
          :disabled="busy"
          v-bind="field.attrs"
          @input="emit('update:value', {
            ...value,
            [field.id]: $event.target.value
          })"
          />
      </slot>
    </div>
    <div class="text-right">
      <button
        type="submit"
        tabindex="-1"
        :disabled="busy"
        class="btn text-xl mt-4"
      >
        <div v-if="busy" class="text-center w-100%">
          <div class="animate-spin preserve-3d m-auto w-2rem h-2rem">
            <i-carbon-progress-bar-round w-2rem h-2rem/>
          </div>
          <span class="sr-only">
            {{ t('Loading...') }}
          </span>
        </div>
        <template v-else>
          {{ t('Save') || props.submitLabel }}
        </template>
      </button>
    </div>
  </form>
</template>
