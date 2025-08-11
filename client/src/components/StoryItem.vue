<template>
  <div class="story-item">
    <div class="story-header">
      <h3 class="story-title">
        <a :href="story.url" target="_blank" rel="noopener">
          {{ story.title }}
        </a>
      </h3>
    </div>

    <div class="story-meta">
      <span class="meta-item points">
        <i class="fas fa-arrow-up"></i>
        {{ story.score }} pontos
      </span>
      <span class="meta-item author">
        <i class="fas fa-user"></i>
        por {{ story.by }}
      </span>

      <span class="meta-item time">
        <i class="fas fa-clock"></i>
        {{ formatTime(story.time) }}
      </span>

      <span 
        v-if="commentCount > 0"
        class="meta-item comments" 
        @click="toggleComments"
        :class="{ active: showComments }"
      >
        <i class="fas fa-comment"></i>
        {{ commentCount }} comentários
      </span>
    </div>

    <div v-if="showComments" class="comments-section">
      <CommentsList :comments="story.comments || []" :story-id="story.id" />
    </div>
  </div>
</template>

<script>
import CommentsList from './CommentsList.vue'

export default {
  name: 'StoryItem',
  components: {
    CommentsList
  },
  
  props: {
    story: {
      type: Object,
      required: true
    }
  },

  data() {
    return {
      showComments: false
    }
  },

  computed: {
    commentCount() {
      const countRecursive = (comments) => {
        if (!comments || !Array.isArray(comments)) return 0
        return comments.reduce((acc, comment) => {
          return acc + 1 + countRecursive(comment.comments)
        }, 0)
      }
      return countRecursive(this.story.comments)
    }
  },

  methods: {
    toggleComments() {
      this.showComments = !this.showComments
    },

    formatTime(timestamp) {
      const date = new Date(timestamp * 1000)
      const now = new Date()
      const diffMs = now - date
      const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
      const diffDays = Math.floor(diffHours / 24)

      if (diffDays > 0) {
        return `${diffDays} dia${diffDays > 1 ? 's' : ''} atrás`
      } else if (diffHours > 0) {
        return `${diffHours} hora${diffHours > 1 ? 's' : ''} atrás`
      } else {
        const diffMinutes = Math.floor(diffMs / (1000 * 60))
        return `${diffMinutes} minuto${diffMinutes > 1 ? 's' : ''} atrás`
      }
    }
  }
}
</script>

<style scoped>
.story-item {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  transition: box-shadow 0.2s ease;
}

.story-item:hover {
  box-shadow: 0 4px 8px rgba(0,0,0,0.15);
}

.story-title {
  margin: 0 0 10px 0;
  font-size: 1.2rem;
  line-height: 1.4;
}

.story-title a {
  color: #333;
  text-decoration: none;
}

.story-title a:hover {
  color: #ff6600;
}

.story-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 20px;
  font-size: 0.9rem;
  color: #666;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 5px;
}

.meta-item i {
  width: 12px;
  text-align: center;
}

.points i {
  color: #ff6600;
}

.author i {
  color: #4a90e2;
}

.time i {
  color: #888;
}

.comments {
  cursor: pointer;
  transition: color 0.2s ease;
}

.comments:hover,
.comments.active {
  color: #ff6600;
}

.comments i {
  color: inherit;
}

.comments-section {
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #eee;
}

@media (max-width: 768px) {
  .story-meta {
    flex-direction: column;
    gap: 10px;
  }
  
  .story-item {
    padding: 15px;
  }
}
</style>
