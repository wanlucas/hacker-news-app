class ServiceFactory
  require_relative '../repositories/cache/base'
  require_relative '../repositories/cache/rails'

  class << self
    def hacker_news_service
      HackerNewsService.new(
        http_client: HttpClient.new('https://hacker-news.firebaseio.com/v0'),
        cache_repository: Repositories::Cache::Rails.new,
        broadcasting_service: BroadcastingService.new,
        logger: Rails.logger,
      )
    end
  end
end
