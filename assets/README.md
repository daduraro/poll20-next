## Caveats

### Logos / svgs
Not sure what's the culprit but there's something wrong with svgs, maybe my svg definition, maybe the browser, maybe the loader `vite-svg-loader`, but these are all solutions that don't work:

* `?url` + `<img>` doesn't allow styling
* `?raw` + `<object>` doesn't allow for dynamic styling as it lives in a separate document
* `?component` + using the component directly breaks the viewbox of the logo, even though the resulting html seems to preserve the width/height/viewBox attributes correctly

Literally just copypasting the svg in the template works, but it's ugly. So would defining the logo in its own `.vue` file. But in the end what seems to work best is `?raw` + `<div v-html="raw"/>` (with the disadvantage that you can't set tags on the svg component directly)

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

Solution: moved to https://github.com/antfu/unplugin-icons (auto resolver still doesn't work for dynamic icons; import icons manually)

```html
import icon from '~icons/carbon/sun'
...
<component :is="icon"/>
```