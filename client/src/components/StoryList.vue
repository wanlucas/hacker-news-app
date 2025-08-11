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
        <span 
          class="websocket-indicator" 
          :class="{ connected: isConnected }"
          :title="getWebSocketTooltip()"
        ></span>
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
import { useStoriesWebSocket } from '../composables/useStoriesWebSocket.js'

export default {
  name: 'StoryList',
  components: { StoryItem },
  setup() {
    return useStoriesWebSocket()
  },
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
  watch: {
    newStories(stories) {
      if (stories && !this.isSearching) {
        this.stories = stories
        this.topStories = stories
      }
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
      } finally { 
        this.loading = false 
      }
    },

    async handleSearch() {
      const q = this.searchQuery.trim()
      if (!q) { 
        this.clearSearch() 
        return 
      }
      
      try {
        this.loading = true
        this.error = null
        const response = await axios.get('http://localhost:3000/api/stories/search', { 
          params: { q, limit: 20 } 
        })
        if (response.data.success) {
          this.stories = response.data.data
          this.isSearching = true
        } else { 
          throw new Error('Busca falhou') 
        }
      } catch (e) {
        console.error(e)
        this.error = 'Erro ao buscar.'
      } finally { 
        this.loading = false 
      }
    },

    clearSearch() {
      this.searchQuery = ''
      this.isSearching = false
      this.stories = this.topStories
    },

    getWebSocketTooltip() {
      return this.isConnected 
        ? '🟢 WebSocket: Conectado'
        : '🔴 WebSocket: Desconectado'
    }
  },
  
  mounted() {
    this.fetchStories()
  }
}
</script>

<style scoped>
.story-list {
  width: 100%;
}

.websocket-indicator {
  display: inline-block;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background-color: #dc3545;
  margin-left: 10px;
  transition: all 0.3s ease;
  box-shadow: 0 0 0 0 rgba(220, 53, 69, 0.7);
  animation: pulse-red 2s infinite;
  cursor: help;
}

.websocket-indicator.connected {
  background-color: #28a745;
  box-shadow: 0 0 0 0 rgba(40, 167, 69, 0.7);
  animation: pulse-green 2s infinite;
}

@keyframes pulse-red {
  0% {
    box-shadow: 0 0 0 0 rgba(220, 53, 69, 0.7);
  }
  70% {
    box-shadow: 0 0 0 6px rgba(220, 53, 69, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(220, 53, 69, 0);
  }
}

@keyframes pulse-green {
  0% {
    box-shadow: 0 0 0 0 rgba(40, 167, 69, 0.7);
  }
  70% {
    box-shadow: 0 0 0 6px rgba(40, 167, 69, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(40, 167, 69, 0);
  }
}

.search-bar {
  display: flex;
  margin: 20px 0;
}

.search-input {
  flex: 1;
  padding: 12px;
  border: 2px solid #ddd;
  border-radius: 6px 0 0 6px;
  font-size: 1rem;
  outline: none;
  transition: border-color 0.2s;
}

.search-input:focus {
  border-color: #ff6600;
}

.search-btn {
  background-color: #ff6600;
  color: white;
  border: none;
  padding: 12px 16px;
  cursor: pointer;
  font-size: 1rem;
  transition: background-color 0.2s;
  display: flex;
  align-items: center;
  gap: 6px;
}

.search-btn:hover {
  background-color: #e55a00;
}

.search-btn:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.clear-btn {
  background-color: #dc3545;
  color: white;
  border: none;
  padding: 10px 12px;
  border-radius: 0 6px 6px 0;
  cursor: pointer;
  font-size: 0.9rem;
  transition: background-color 0.2s;
}

.clear-btn:hover {
  background-color: #c82333;
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
  color: white;
  border: none;
  padding: 10px 16px;
  border-radius: 6px;
  cursor: pointer;
  margin-top: 10px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.retry-btn:hover {
  background-color: #e55a00;
}

.stories h2 {
  color: #333;
  margin-bottom: 20px;
  font-size: 1.5rem;
  display: flex;
  align-items: center;
}

.back-to-top-wrapper {
  margin-bottom: 20px;
}

.back-top-btn {
  background-color: #6c757d;
  color: white;
  border: none;
  padding: 8px 12px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.back-top-btn:hover {
  background-color: #5a6268;
}

.story-item {
  margin-bottom: 15px;
}
</style>