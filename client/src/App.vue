<template>
  <div id="app">
    <header class="header">
      <div class="header-content">
        <h1>HN</h1>
        <span class="header-subtitle">Hacker News</span>
      </div>
    </header>

    <main class="main">
      <StoryList />
    </main>
  </div>
</template>

<script>
import StoryList from './components/StoryList.vue'

export default {
  name: 'App',
  components: {
    StoryList
  }
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

#app {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background-color: #f9fafb;
  min-height: 100vh;
  color: #2d3748;
}

.header {
  background-color: #ffffff;
  border-bottom: 1px solid #e6e6e6;
  padding: 16px 20px;
  position: sticky;
  top: 0;
  z-index: 100;
  backdrop-filter: blur(10px);
  background-color: rgba(255, 255, 255, 0.95);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1), 0 1px 2px rgba(0, 0, 0, 0.06);
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  gap: 12px;
}

.header h1 {
  font-size: 1.5rem;
  font-weight: 700;
  color: #2d3748;
  margin: 0;
  letter-spacing: -0.025em;
}

.header-subtitle {
  font-size: 0.875rem;
  color: #718096;
  font-weight: 500;
}

.main {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px 20px;
}
</style>
