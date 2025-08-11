class StoriesUpdateJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting periodic stories update"
    
    begin
      ServiceFactory.hacker_news_service.update_cache

      Rails.logger.info "Stories updated successfully"
      
    rescue => error
      Rails.logger.error "Failed to update stories: #{error.message}"
      raise error
    end
  end
end
