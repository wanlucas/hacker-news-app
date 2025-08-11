<template>
  <div class="story-list">
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
      <h2>📰 Top Stories ({{ stories.length }})</h2>
      
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
  components: {
    StoryItem
  },
  
  data() {
    return {
      stories: [],
      loading: true,
      error: null
    }
  },

  methods: {
    async fetchStories() {
      try {
        this.loading = true
        this.error = null

        const response = await axios.get('http://localhost:3000/api/stories')

        console.log(response.data)
  
        if (response.data.success) {
          this.stories = response.data.data
        } else {
          throw new Error('Falha ao carregar stories')
        }
        
      } catch (error) {
        console.error('Erro ao buscar stories:', error)
        this.error = 'Não foi possível carregar as stories. Verifique se o servidor está rodando.'
      } finally {
        this.loading = false
      }
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

.loading, .error {
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
  padding: 10px 20px;
  border-radius: 5px;
  cursor: pointer;
  margin-top: 10px;
  font-size: 1rem;
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
</style>
