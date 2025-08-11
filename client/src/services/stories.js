import apiClient from '../lib/api.js'

class StoriesService {
  async getStories() {
    try {
      const response = await apiClient.get('/api/stories')
      return response.data
    } catch (error) {
      throw new Error(`Erro ao buscar stories: ${error.message}`)
    }
  }

  async searchStories(query, limit = 20) {
    try {
      const response = await apiClient.get('/api/stories/search', {
        params: { q: query, limit }
      })
      return response.data
    } catch (error) {
      throw new Error(`Erro na busca: ${error.message}`)
    }
  }
}

export default new StoriesService()
