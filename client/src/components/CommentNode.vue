<template>
  <div 
    class="comment-node" 
    :style="{ 
      marginLeft: depth > 0 ? depth * 14 + 'px' : '0',
      '--depth': depth 
    }"
  >
    <div class="comment-header">
      <span class="author"><i class="fas fa-user"></i> {{ comment.by || 'anônimo' }}</span>
      <span class="time"><i class="fas fa-clock"></i> {{ formatTime(comment.time) }}</span>
      <button v-if="hasChildren" class="toggle-btn" @click="toggle">
        <i :class="collapsed ? 'fas fa-plus' : 'fas fa-minus'"></i>
        {{ collapsed ? 'expandir' : 'recolher' }}
      </button>
    </div>

    <div class="comment-body" v-html="sanitizedText"></div>

    <transition name="fade">
      <div v-if="!collapsed && hasChildren" class="children">
        <CommentNode
          v-for="child in comment.comments"
          :key="child.id"
            :comment="child"
            :depth="depth + 1"
        />
      </div>
    </transition>
  </div>
</template>

<script>
import DOMPurify from 'dompurify'
export default {
  name: 'CommentNode',
  props: {
    comment: { type: Object, required: true },
    depth: { type: Number, default: 0 }
  },
  data() { return { collapsed: false } },
  computed: {
    hasChildren() { return this.comment.comments && this.comment.comments.length > 0 },
    sanitizedText() { return DOMPurify.sanitize(this.comment.text || '') }
  },
  methods: {
    toggle() { this.collapsed = !this.collapsed },
    formatTime(ts) {
      if (!ts) return ''
      const date = new Date(ts * 1000)
      const diff = (Date.now() - date.getTime()) / 1000
      const h = Math.floor(diff / 3600)
      const d = Math.floor(h / 24)
      if (d > 0) return `${d} dia${d>1?'s':''}`
      if (h > 0) return `${h} hora${h>1?'s':''}`
      const m = Math.floor(diff / 60)
      return `${m} min`
    }
  }
}
</script>

<style scoped>
.comment-node {
  background: #fff;
  border: 1px solid #eee;
  border-radius: 6px;
  padding: 10px 12px;
  position: relative;
}

.comment-node + .comment-node {
  margin-top: 8px;
}

.comment-header {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  align-items: center;
  font-size: 0.75rem;
  margin-bottom: 6px;
  color: #555;
}

.author i,
.time i {
  color: #888;
  margin-right: 4px;
}

.toggle-btn {
  background: none;
  border: none;
  color: #2c3e50;
  font-size: 0.7rem;
  cursor: pointer;
  padding: 2px 6px;
  border-radius: 4px;
}

.toggle-btn:hover {
  background: rgba(44, 62, 80, 0.1);
}

.comment-body {
  font-size: 0.85rem;
  line-height: 1.3;
  color: #333;
}

.comment-body :deep(p) {
  margin: 4px 0;
}

.children {
  margin-top: 8px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity .15s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

@media (max-width: 768px) {
  .comment-node {
    padding: 8px 10px;
    margin-left: 0 !important;
  }
  
  .comment-node[style*="margin-left"] {
    margin-left: calc(var(--depth, 0) * 8px) !important;
  }
  
  .comment-header {
    gap: 8px;
    font-size: 0.7rem;
  }
  
  .comment-body {
    font-size: 0.8rem;
  }
  
  .children {
    gap: 6px;
    margin-top: 6px;
  }
  
  .comment-node + .comment-node {
    margin-top: 6px;
  }
}
</style>
