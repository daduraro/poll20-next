import path from 'node:path'
import VueI18n from '@intlify/unplugin-vue-i18n/vite'
import Vue from '@vitejs/plugin-vue'
import Unocss from 'unocss/vite'
import AutoImport from 'unplugin-auto-import/vite'
import IconsResolver from 'unplugin-icons/resolver'
import Icons from 'unplugin-icons/vite'
import Components from 'unplugin-vue-components/vite'
import { defineConfig } from 'vite'
import { VitePWA } from 'vite-plugin-pwa'
import Layouts from 'vite-plugin-vue-layouts-next'
import svgLoader from 'vite-svg-loader'
import VueRouter from 'vue-router/vite'

export default defineConfig({
  build: {
    outDir: '../priv/static',
    // priv/static only holds build output, but lives outside the Vite root so it isn't emptied by default
    emptyOutDir: true,
  },

  define: {
    // shown on the about page as the last update; set when the frontend is built (i.e. deployed)
    __BUILD_DATE__: JSON.stringify(new Date().toISOString()),
  },

  resolve: {
    alias: {
      '~/': `${path.resolve(import.meta.dirname, 'src')}/`,
    },
  },

  optimizeDeps: {
    // pages are lazy-loaded through a virtual module the dependency scanner doesn't follow,
    // so scan them directly; otherwise their deps are found on first visit and force a reload
    entries: ['index.html', 'src/pages/**/*.vue'],
  },

  plugins: [
    // File-based routing from src/pages, must come before Vue()
    // https://router.vuejs.org/file-based-routing/
    VueRouter({
      dts: 'src/typed-router.d.ts',
    }),

    Vue(),

    // https://github.com/loicduong/vite-plugin-vue-layouts-next
    Layouts(),

    // https://github.com/antfu/unplugin-auto-import
    AutoImport({
      imports: [
        'vue',
        'vue-router',
        'vue-i18n',
        '@vueuse/core',
        { '@unhead/vue': ['useHead'] },
      ],
      dts: 'src/auto-imports.d.ts',
      dirs: [
        'src/composables',
        'src/stores',
      ],
      vueTemplate: true,
    }),

    svgLoader(),

    // https://github.com/antfu/unplugin-vue-components
    Components({
      dts: 'src/components.d.ts',
      resolvers: [
        IconsResolver(),
      ],
    }),

    // https://github.com/antfu/unocss
    // see unocss.config.ts for config
    Unocss(),
    Icons(),

    // https://github.com/antfu/vite-plugin-pwa
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.svg'],
      outDir: '../priv/static',
      manifest: {
        name: 'Poll20',
        short_name: 'Poll20',
        theme_color: '#f87171',
        icons: [
          {
            src: '/pwa-192x192.png',
            sizes: '192x192',
            type: 'image/png',
          },
          {
            src: '/pwa-512x512.png',
            sizes: '512x512',
            type: 'image/png',
          },
          {
            src: '/pwa-512x512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'any maskable',
          },
        ],
      },
    }),

    // https://github.com/intlify/bundle-tools/tree/main/packages/unplugin-vue-i18n
    VueI18n({
      runtimeOnly: true,
      compositionOnly: true,
      fullInstall: true,
      include: [path.resolve(import.meta.dirname, 'locales/**')],
    }),
  ],
})
