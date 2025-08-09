class Api::StoriesController < ApplicationController
  def index
    # raise "Erro de teste para verificar o handler!"
    
    stories_ids = HackerNewsService.get_top_story_ids(15)

    stories = HackerNewsService.find_stories_by_ids(stories_ids)

    render json: {
      success: true,
      data: stories,
      count: stories.length
    }
  end
end
