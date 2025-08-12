class Api::StoriesController < ApplicationController
  include InputSanitizer

  def index    
    stories = ServiceFactory.hacker_news_service.get_top_stories

    render json: {
      success: true,
      data: stories,
      count: stories.length,
    }
  end

  def search
    query = sanitize_input(params[:q])
    limit = [params[:limit]&.to_i || 10, 50].min
    stories = ServiceFactory.hacker_news_service.search_stories(query, limit)

    render json: {
      success: true,
      data: stories,
      count: stories.length,
    }
  end

  def update
    info = ServiceFactory.hacker_news_service.update_cache
    render json: { success: true, data: info }
  end
end
