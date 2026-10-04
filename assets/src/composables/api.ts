import type { UseFetchOptions } from '@vueuse/core'
import type { MaybeArray, UUID } from '~/types'
import { createFetch } from '@vueuse/core'
import NProgress from 'nprogress'

interface EntityBase {
  id: UUID
  type: string
}

type EntityData<T = any> = EntityBase & {
  attributes: Partial<T>
  relationships: Record<string, {
    data?: MaybeArray<Pick<EntityData, 'id'>>
  }>
}

interface ApiResponse<T> {
  data: MaybeArray<EntityData<T>>
  included: EntityData[]
}

type Method = 'get' | 'post' | 'patch' | 'delete'

interface ApiOptions {
  query?: Record<string, any>
  attributes?: Record<string, any>
}

function serialize<T>(entity: EntityData<T>, included: EntityData[] = []): T {
  return {
    id: entity.id,
    ...entity.attributes,
    ...Object.fromEntries(
      Object.entries(entity.relationships)
        .filter(([, value]) => value.data !== undefined)
        .map(([key, value]) => {
          const getRelated = (item: EntityBase): EntityData => included.find(match => match.id === item.id && match.type === item.type)!
          const isMultiple = Array.isArray(value.data)
          const related = isMultiple
            ? (value.data as EntityBase[]).map(item => serialize(getRelated(item), included))
            : serialize(getRelated(value.data as EntityBase), included)
          return [key, related]
        }),
    ),
  } as T
}

const baseUrl = import.meta.env.DEV
  ? 'http://127.0.0.1:4000/api'
  : '/api'

const apiFetch = createFetch({
  baseUrl,
  options: {
    beforeFetch: ({ options }) => {
      NProgress.start()
      const { membership } = useUserStore()
      options.headers = {
        ...options.headers,
        'Accept': 'application/vnd.api+json',
        'Content-Type': 'application/vnd.api+json',
        'x-member-id': membership?.member_id || '',
      }
      return { options }
    },
    afterFetch<T>(context: { data: ApiResponse<T> & { [key: string]: any } }) {
      NProgress.done()
      if (context.data) {
        context.data.entity = Array.isArray(context.data.data)
          ? undefined
          : serialize(context.data.data, context.data.included)
        context.data.entities = !Array.isArray(context.data.data)
          ? undefined
          : context.data.data.map(item => serialize(item, context.data.included))
      }

      return context
    },
    onFetchError(ctx) {
      NProgress.done()
      return ctx
    },
  },
})

// set by afterFetch: `entity` for single resources, `entities` for lists
interface ApiReturn<T> {
  entity?: T
  entities?: T[]
  // from the raw response; `next` is null on the last page of a paginated list
  links?: {
    next?: string | null
  }
}

export function useApi<T>(
  method: Method,
  path: string,
  payload: ApiOptions = {
    query: {},
    attributes: undefined,
  },
  options: UseFetchOptions = {},
) {
  const url = `${path}?${(new URLSearchParams(payload.query)).toString()}`
  const body = payload.attributes === undefined
    ? undefined
    : {
        data: {
          attributes: payload.attributes,
        },
      }
  return apiFetch(url, options)[method](body).json<ApiReturn<T>>()
}
