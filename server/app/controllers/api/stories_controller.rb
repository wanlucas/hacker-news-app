class Api::StoriesController < ApplicationController
  def index    

    limit = [params[:limit]&.to_i || 15, 50].min

    stories = HackerNewsService.instance.get_top_stories(limit)

    render json: {
      success: true,
      data: stories,
      count: stories.length,
    }
  end
end
