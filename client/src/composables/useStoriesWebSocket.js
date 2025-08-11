import { ref, onMounted, onUnmounted } from 'vue'

export function useStoriesWebSocket(serverUrl = 'ws://localhost:3000/cable') {
  const isConnected = ref(false)
  const newStories = ref(null)

  let cable = null        
  let storiesChannel = null

  const connect = () => {
    try {
      if (typeof ActionCable === 'undefined') return

      cable = ActionCable.createConsumer(serverUrl)

      storiesChannel = cable.subscriptions.create(
        { channel: 'StoriesChannel' },
        {
          connected() {
            console.log('✅ WebSocket conectado ao StoriesChannel')
            isConnected.value = true
          },

          disconnected() {
            console.log('❌ WebSocket desconectado do StoriesChannel')
            isConnected.value = false  // Atualiza estado reativo
          },

          received(data) {
            if (data.type === 'new_stories') {
    
              newStories.value = data.data
            }
          }
        }
      )
    } catch (error) {
      console.error('❌ Erro na conexão WebSocket:', error)
    }
  }

  const disconnect = () => {
    if (cable) {
      console.log('🔌 Desconectando WebSocket...')
      cable.disconnect()       // Fecha conexão
      isConnected.value = false
    }
  }

  onMounted(() => {
    connect()
  })

  onUnmounted(() => {
    disconnect()
  })

  return {
    isConnected,
    newStories,
    connect,
    disconnect
  }
}
