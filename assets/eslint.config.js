import antfu from '@antfu/eslint-config'

export default antfu({
  ignores: ['src/auto-imports.d.ts', 'src/components.d.ts', 'src/typed-router.d.ts'],
}, {
  rules: {
    // would add install-behaviour settings (trustPolicy, shellEmulator...) to pnpm-workspace.yaml
    'pnpm/yaml-enforce-settings': 'off',
  },
})
