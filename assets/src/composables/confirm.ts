import { useConfirmDialog as _useConfirmDialog } from "@vueuse/core";
import { ref } from "vue";
import { wrap } from "~/lib/utils/function";

/**
 * Make the confirm composable auto-cancel after a set time
 */
export function withTiming(timeout = 2000) {
  let handler: any
  return (dialog) => ({
    ...dialog,
    reveal: wrap(dialog.reveal, (callback, ...args) => {
      handler && clearTimeout(handler)
      handler = setTimeout(dialog.cancel, timeout)
      return callback(...args)
    })
  })
}

/**
 * Make the confirm composable auto-cancel after a set time
 */
export function withArguments() {
  return (dialog) => {
    dialog.revealArguments = ref<any[]>([])
    dialog.reveal = wrap(dialog.reveal, (callback, ...args) => {
      dialog.revealArguments.value = args
      return callback(...args)
    })
    return dialog
  }
}