<template>
  <div class="comments-placeholder">
    <p><i class="fas fa-info-circle"></i> Comentários serão implementados na próxima etapa!</p>
    <p>Story ID: {{ storyId }}</p>
  </div>
</template>

<script>
export default {
  name: 'CommentsList',
  props: {
    storyId: {
      type: Number,
      required: true
    }
  }
}
</script>

<style scoped>
.comments-placeholder {
  text-align: center;
  padding: 20px;
  background-color: #f9f9f9;
  border-radius: 5px;
  color: #666;
}

.comments-placeholder i {
  color: #4a90e2;
  margin-right: 5px;
}
</style>
