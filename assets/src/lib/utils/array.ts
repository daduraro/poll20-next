export const randomPick = <T extends Array<any>>(items: T): T[number] => {
  return items[Math.floor(Math.random() * items.length)]
}

/**
 * Sort array by several criteria. Compares values one by one until there are no ties.
 * Example: sort people first by oldest, then name (a-z):
 * ```
 * sortByTiered(
 *  ({ age, name }) => [-age, name],
 *  people
 * )
 * ```
 */
export function sortByTiered<T>(getValues: ((value: T) => (number|string)[]), array: T[]): T[] {
  const copy = array.slice()
  copy.sort((a, b) => {
    const aValues = getValues(a)
    const bValues = getValues(b)
    const tieBreaker = aValues.findIndex((value, index) => value !== bValues[index])
    return (tieBreaker !== -1 && aValues[tieBreaker] !== bValues[tieBreaker])
      ? (aValues[tieBreaker] < bValues[tieBreaker] ? -1 : +1)
      : 0
  })
  return copy
}