import { DirectiveBinding } from 'vue'
import { type UserModule } from '~/types'

export const install: UserModule = ({ app }) => {
  const updateTitle = (element: HTMLElement, binding: DirectiveBinding) => 
    ['aria-label', 'title'].forEach(attribute => element.setAttribute(attribute, binding.value))

  app.directive('aria-title', {
    mounted: updateTitle,
    updated: updateTitle,
  })
}
