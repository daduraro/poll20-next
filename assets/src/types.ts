import { type ViteSSGContext } from 'vite-ssg'

export type MaybeArray<T> = T|T[]
export type ElementType<T> = T extends any[] ? T[number] : never;

export type UserModule = (ctx: ViteSSGContext) => void

export type UUID = string

export type Room = {
  id: UUID
  type: string
  name: string
  invite_code: UUID
}

export type Member = {
  id: UUID
  name: string
}