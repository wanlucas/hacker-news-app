class StoriesChannel < ActionCable::Channel::Base
  def subscribed
    stream_from "stories_updates"
    
    Rails.logger.info "Cliente conectado ao StoriesChannel (stream: stories_updates)"
  end

  def unsubscribed
    Rails.logger.info "Cliente desconectado do StoriesChannel"
  end
  
  class << self
    def broadcast_new_stories(stories)
      message = {
        type: 'new_stories',
        data: stories
      }
      
      ActionCable.server.broadcast('stories_updates', message)
      
      Rails.logger.info "WebSocket broadcast enviado: #{stories.size} novas stories"
    end
  end
end