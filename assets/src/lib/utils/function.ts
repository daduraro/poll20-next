export const wrap = <T extends Array<any>, K>(
    fn: (...args: T) => K,
    callback: (fn: (...args: T) => K, ...args: T) => K,
) => {
    return (...args: T): K => {
        return callback(fn, ...args)
    }
}