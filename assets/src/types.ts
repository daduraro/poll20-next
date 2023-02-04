import { type ViteSSGContext } from 'vite-ssg'

export type MaybeArray<T> = T|T[]
export type ElementType<T> = T extends any[] ? T[number] : never;

export type UserModule = (ctx: ViteSSGContext) => void

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
}


export type Session = {
  id: UUID;
  created_at: string;
  attendees: Attendee[];
}

export type Vote = {
  id: UUID;
  game_id: Game['id'];
  member_id: Game['id'];
  value: -1|1;
  created_at: string;
}
export type Attendee = {
  member_id: Member['id'];
  winner: boolean;
  vote: Vote['value'];
}