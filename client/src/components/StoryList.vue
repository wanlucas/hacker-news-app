<template>
  <div class="story-list">
    <form class="search-bar" @submit.prevent="handleSearch">
      <input
        v-model="searchQuery"
        type="text"
        placeholder="Buscar por palavra-chave..."
        class="search-input"
      />
      <button type="submit" class="search-btn" :disabled="loading">
        <i class="fas fa-search"></i>
        Buscar
      </button>
      <button
        v-if="searchQuery"
        type="button"
        class="clear-btn"
        @click="clearSearch"
        :disabled="loading"
      >
        <i class="fas fa-times"></i>
      </button>
    </form>

    <div v-if="loading" class="loading">
      <i class="fas fa-spinner fa-spin"></i>
      <p>Carregando stories...</p>
    </div>

    <div v-else-if="error" class="error">
      <i class="fas fa-exclamation-triangle"></i>
      <p>{{ error }}</p>
      <button @click="fetchStories" class="retry-btn">
        <i class="fas fa-redo"></i>
        Tentar novamente
      </button>
    </div>

    <div v-else class="stories">
      <h2>
        📰 {{ isSearching ? 'Resultados da busca' : 'Top Stories' }} ({{ stories.length }})
      </h2>
      <div v-if="isSearching" class="back-to-top-wrapper">
        <button class="back-top-btn" @click="clearSearch" :disabled="loading">
          <i class="fas fa-arrow-left"></i>
          Voltar para Top Stories
        </button>
      </div>
      <div v-for="story in stories" :key="story.id" class="story-item">
        <StoryItem :story="story" />
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'
import StoryItem from './StoryItem.vue'

export default {
  name: 'StoryList',
  components: { StoryItem },
  data() {
    return {
      stories: [],
      topStories: [],
      loading: true,
      error: null,
      searchQuery: '',
      isSearching: false,
    }
  },
  methods: {
    async fetchStories() {
      try {
        this.loading = true
        this.error = null
        const response = await axios.get('http://localhost:3000/api/stories')
        if (response.data.success) {
          this.stories = response.data.data
          this.topStories = response.data.data
          this.isSearching = false
        } else {
          throw new Error('Falha ao carregar stories')
        }
      } catch (error) {
        console.error('Erro ao buscar stories:', error)
        this.error = 'Não foi possível carregar as stories.'
      } finally { this.loading = false }
    },
    async handleSearch() {
      const q = this.searchQuery.trim()
      if (!q) { this.clearSearch(); return }
      try {
        this.loading = true
        this.error = null
        const response = await axios.get('http://localhost:3000/api/stories/search', { params: { q, limit: 20 } })
        if (response.data.success) {
          this.stories = response.data.data
          this.isSearching = true
        } else { throw new Error('Busca falhou') }
      } catch (e) {
        console.error(e)
        this.error = 'Erro ao buscar.'
      } finally { this.loading = false }
    },
    clearSearch() {
      this.searchQuery = ''
      this.isSearching = false
      this.stories = this.topStories
    }
  },
  mounted() { this.fetchStories() }
}
</script>

<style scoped>
.story-list {
  width: 100%;
}

.loading,
.error {
  text-align: center;
  padding: 40px;
  color: #666;
}

.loading i {
  font-size: 2rem;
  color: #ff6600;
  margin-bottom: 10px;
}

.error {
  background-color: #fee;
  border: 1px solid #fcc;
  border-radius: 8px;
  margin: 20px 0;
}

.error i {
  color: #d33;
  font-size: 1.5rem;
  margin-bottom: 10px;
}

.retry-btn {
  background-color: #ff6600;
  color: #ffffff;
  border: none;
  padding: 10px 20px;
  border-radius: 5px;
  cursor: pointer;
  margin-top: 10px;
  font-size: 1rem;
  transition: background-color .15s ease;
}

.retry-btn:hover {
  background-color: #e55a00;
}

.stories h2 {
  color: #333;
  margin-bottom: 20px;
  font-size: 1.5rem;
}

.story-item {
  margin-bottom: 15px;
}

.search-bar {
  display: flex;
  gap: 8px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.search-input {
  flex: 1 1 260px;
  padding: 10px 12px;
  border: 1px solid #ccc;
  border-radius: 6px;
  font-size: 0.95rem;
  transition: border-color .15s ease, box-shadow .15s ease;
}

.search-input:focus {
  outline: none;
  border-color: #ff6600;
  box-shadow: 0 0 0 2px rgba(255, 102, 0, 0.15);
}

.search-btn,
.clear-btn,
.back-top-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: #ff6600;
  color: #ffffff;
  border: none;
  padding: 10px 14px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.85rem;
  font-weight: 600;
  transition: background .15s ease;
}

.clear-btn {
  background: #888;
}

.back-top-btn {
  background: #555;
  margin-top: 10px;
}

.search-btn:hover {
  background: #e85c00;
}

.clear-btn:hover {
  background: #666;
}

.back-top-btn:hover {
  background: #333;
}

.search-btn:disabled,
.clear-btn:disabled,
.back-top-btn:disabled {
  opacity: .6;
  cursor: not-allowed;
}

.back-to-top-wrapper {
  margin: 10px 0 15px;
}
</style>
