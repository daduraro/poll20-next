import {
  defineConfig,
  presetAttributify,
  presetTypography,
  presetUno,
  presetWebFonts,
  transformerDirectives,
  transformerVariantGroup,
} from 'unocss'

export default defineConfig({
  shortcuts: [
    ['btn', 'px-4 py-1 rounded inline-block bg-sky-500 text-white cursor-pointer hover:bg-sky-700 disabled:cursor-default disabled:bg-gray-600 disabled:opacity-50'],
    ['btn-danger', 'btn bg-red-500 hover:bg-red-800!'],
    ['icon-btn', 'inline-block select-none opacity-85 transition duration-200 ease-in-out hover:opacity-100 hover:text-sky-600'],
    ['input', 'border-1 border-sky-500 bg-transparent rounded pl-1 text-lg'],
    ['form-field', 'mb-2 items-baseline'],
  ],
  presets: [
    presetUno(),
    presetAttributify(),
    presetTypography(),
    presetWebFonts({
      fonts: {
        sans: 'DM Sans',
        serif: 'DM Serif Display',
        mono: 'DM Mono',
      },
    }),
  ],
  transformers: [
    transformerDirectives(),
    transformerVariantGroup(),
  ],
  safelist: 'prose prose-sm m-auto text-left'.split(' '),
})
