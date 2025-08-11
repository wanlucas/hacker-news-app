class ServiceFactory
  require_relative '../repositories/cache/base'
  require_relative '../repositories/cache/memory'
  require_relative '../repositories/cache/rails'

  class << self
    def hacker_news_service(environment: Rails.env)
      HackerNewsService.new(cache_repository: Repositories::Cache::Rails.new)
    end
  end
end
