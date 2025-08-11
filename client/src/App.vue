<template>
  <div id="app">
    <header class="header">
      <h1>🔥 Hacker News Forum</h1>
      <p>Top stories from Hacker News</p>
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
  background-color: #f6f6ef;
  min-height: 100vh;
}

.header {
  background-color: #ff6600;
  color: white;
  padding: 20px;
  text-align: center;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.header h1 {
  font-size: 2rem;
  margin-bottom: 5px;
}

.header p {
  opacity: 0.9;
  font-size: 1rem;
}

.main {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}
</style>
