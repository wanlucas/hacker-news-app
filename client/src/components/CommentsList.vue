<template>
  <div class="comments-wrapper">
    <h4 class="comments-title" v-if="comments.length">💬 Comentários ({{ totalComments }})</h4>
    <p v-else class="no-comments">Nenhum comentário válido encontrado.</p>

    <div class="comments-tree" v-if="comments.length">
      <CommentNode
        v-for="comment in comments"
        :key="comment.id"
        :comment="comment"
        :depth="0"
      />
    </div>
  </div>
</template>

<script>
import DOMPurify from 'dompurify'
import CommentNode from './CommentNode.vue'

export default {
  name: 'CommentsList',
  components: { CommentNode },
  props: {
    comments: {
      type: Array,
      required: true,
      default: () => []
    },
    storyId: { type: Number, required: true }
  },
  computed: {
    totalComments() {
      const countRecursive = (list) => list.reduce((acc, c) => acc + 1 + (c.comments ? countRecursive(c.comments) : 0), 0)
      return countRecursive(this.comments)
    }
  },
  methods: { sanitize(html) { return DOMPurify.sanitize(html || '') } }
}
</script>

<style scoped>

.comments-wrapper {
  margin-top: 10px;
}

.comments-title {
  margin: 0 0 10px;
  font-size: 1rem;
  color: #333;
}

.no-comments {
  font-size: 0.9rem;
  color: #777;
  font-style: italic;
}

.comments-tree {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
</style>
