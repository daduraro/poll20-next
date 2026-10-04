import { useConfirmDialog as _useConfirmDialog, type UseConfirmDialogReturn } from "@vueuse/core";
import { ref, type Ref } from "vue";
import { wrap } from "~/lib/utils/function";

type Dialog = UseConfirmDialogReturn<any, any, any>

/**
 * Make the confirm composable auto-cancel after a set time
 */
export function withTiming(timeout = 2000) {
  let handler: any
  return <D extends Dialog>(dialog: D): D => ({
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
  return <D extends Dialog>(dialog: D): D & { revealArguments: Ref<any[]> } => {
    const revealArguments = ref<any[]>([])
    dialog.reveal = wrap(dialog.reveal, (callback, ...args) => {
      revealArguments.value = args
      return callback(...args)
    })
    return Object.assign(dialog, { revealArguments })
  }
}
