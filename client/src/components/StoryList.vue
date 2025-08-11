<template>
  <div class="story-list">
    <div class="header-section">
      <h2>
        📰 {{ isSearching ? 'Resultados da busca' : 'Top Stories' }} ({{ stories.length }})
        <span 
          class="websocket-indicator" 
          :class="{ connected: isConnected }"
          :title="getWebSocketTooltip()"
        ></span>
      </h2>
    </div>

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

.header-section {
  margin-bottom: 15px;
}

.header-section h2 {
  color: #333;
  font-size: 1.5rem;
  display: flex;
  align-items: center;
  margin: 0;
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
  gap: 8px;
  margin: 15px 0;
}

.search-input {
  flex: 1;
  padding: 8px 12px;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  font-size: 0.9rem;
  outline: none;
  transition: all 0.2s ease;
  background: #fafafa;
}

.search-input:focus {
  border-color: #2c3e50;
  background: #ffffff;
  box-shadow: 0 0 0 2px rgba(44, 62, 80, 0.1);
}

.search-btn {
  background: #2c3e50;
  color: #ffffff;
  border: none;
  padding: 8px 16px;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.85rem;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 4px;
  min-width: 70px;
  justify-content: center;
}

.search-btn:hover {
  background: #1a252f;
  transform: translateY(-1px);
}

.search-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
  transform: none;
}

.clear-btn {
  background: #888;
  color: #ffffff;
  border: none;
  padding: 8px 12px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 0.8rem;
  transition: all 0.2s ease;
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.clear-btn:hover {
  background: #666;
  transform: scale(1.1);
}

.loading,
.error {
  text-align: center;
  padding: 40px;
  color: #666;
}

.loading i {
  font-size: 2rem;
  color: #2c3e50;
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
  background-color: #2c3e50;
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
  background-color: #1a252f;
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