import type { App } from 'vue'
import type { Router } from 'vue-router'

export type MaybeArray<T> = T|T[]
export type ElementType<T> = T extends any[] ? T[number] : never;

export type UserModule = (ctx: { app: App, router: Router }) => void

export type UUID = string

export type Room = {
  id: UUID;
  type: string;
  name: string;
  invite_code: UUID;
}

export type Member = {
  id: UUID;
  name: string;
}

export type Game = {
  id: UUID;
  name: string;
  owners: Member[];
  players_min: number|null;
  players_max: number|null;
  match_all_owners: boolean;
}


export type Session = {
  id: UUID;
  inserted_at: string;
  comment: string|null;
  game: Game;
  attendees: Attendee[];
}

export type Vote = {
  id: UUID;
  game_id: Game['id'];
  member_id: Member['id'];
  value: -1|1;
  inserted_at: string;
}
export type Attendee = {
  member_id: Member['id'];
  winner: boolean;
  vote: Vote['value']|null;
}