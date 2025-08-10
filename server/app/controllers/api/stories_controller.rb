class Api::StoriesController < ApplicationController
  def index    
    stories = HackerNewsService.instance.get_top_stories

    render json: {
      success: true,
      data: stories,
      count: stories.length,
    }
  end

  def search
    query = params[:q]
    limit = [params[:limit]&.to_i || 10, 50].min

    if query.blank?
      render json: { 
        success: false, 
        message: 'Query parameter is required'
      }, status: :bad_request
      return
    end

    stories = HackerNewsService.instance.search_stories(query, limit)

    render json: {
      success: true,
      data: stories,
      count: stories.length,
    }
  end
end