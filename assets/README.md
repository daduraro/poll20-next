## Caveats

### Icons
https://github.com/unocss/unocss/tree/main/packages/preset-icons

Something about Vitesse template makes dynamic icons not (always) work. You're supposed to be able to define icons in any of these ways:
```html
<i-carbon-sun />
<div i="carbon-sun" />
<i-carbon-sun" />
```

But these don't work for dynamic icons:
```html
const icon = 'carbon-sun'
...
<div :i="icon" />
<div :class="`i-${icon}`" />
<div v-bind="{i: icon}"/>
```

It might have something to do with static site css optimizations.

Solution: moved to https://github.com/antfu/unplugin-icons (auto resolver still doesn't work; import icons manually)

```html
import icon from '~icons/carbon/sun'
...
<component :is="icon"/>
```