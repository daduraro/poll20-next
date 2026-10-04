import type { App } from 'vue'
import type { Router } from 'vue-router'
import type { components } from './api-schema'

export type MaybeArray<T> = T | T[]
export type ElementType<T> = T extends any[] ? T[number] : never

export type UserModule = (ctx: { app: App, router: Router }) => void

export type UUID = string

/*
 * API resources, generated from the backend's OpenAPI spec (`mix api.spec`, then `pnpm api:types`).
 * `useApi` flattens a JSON:API resource object into its id plus its attributes; relationships
 * are only present when requested with `include`, so they're added below where they're loaded.
 */
type Schemas = components['schemas']
type ResourceName = 'room' | 'member' | 'game' | 'session' | 'session_member' | 'vote'
// the api always returns every attribute; nullable ones are just marked as optional in the spec
type Entity<Name extends ResourceName> = { id: UUID } & Required<NonNullable<Schemas[Name]['attributes']>>

// ash_json_api has no OpenAPI type for `timestamps()` (usec datetimes); they're ISO strings
interface Timestamps {
  inserted_at: string
  updated_at: string
}

export type Room = Entity<'room'>

// `has_sessions` is an aggregate, only there when requested (the room's members, see the user store)
export type Member = Omit<Entity<'member'>, 'has_sessions'> & {
  has_sessions?: boolean
}

// `last_played_at` is an aggregate (latest session's `inserted_at`), which the spec leaves untyped
export type Game = Omit<Entity<'game'>, 'last_played_at'> & {
  last_played_at: string | null
  owners: Member[]
}

export type Vote = Omit<Entity<'vote'>, keyof Timestamps> & Timestamps

// a session_member, as created when logging a session
export type Attendee = Pick<Entity<'session_member'>, 'member_id' | 'winner' | 'vote'>

export type Session = Omit<Entity<'session'>, keyof Timestamps> & Timestamps & {
  game: Game
  attendees: Attendee[]
}
