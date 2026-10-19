import { defineStore } from 'pinia'

export const useAppStore = defineStore('app', {
  state: () => ({ menuOpen: false, selectedCategory: '全部' }),
  actions: {
    toggleMenu() { this.menuOpen = !this.menuOpen },
    closeMenu() { this.menuOpen = false },
    selectCategory(category) { this.selectedCategory = category }
  }
})
