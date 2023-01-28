export const randomPick = <T extends Array<any>>(items: T): T[number] => {
  return items[Math.floor(Math.random() * items.length)]
}