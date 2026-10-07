// see `define` in vite.config.ts
declare const __BUILD_DATE__: string

declare interface Window {
  // extend the window
}

declare module '*.vue' {
  import type { DefineComponent } from 'vue'

  const component: DefineComponent<object, object, any>
  export default component
}
