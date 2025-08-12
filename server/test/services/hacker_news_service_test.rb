require 'test_helper'

require_relative '../support/mock_broadcasting_service'

class HackerNewsServiceTest < ActiveSupport::TestCase
  def setup
    @http_client = mock_http_client
    @cache_repository = mock_cache_repository
    @broadcasting_service = mock_broadcasting_service
    @logger = mock_logger
  end

  test "should initialize with all required dependencies" do
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )

    assert_not_nil service
    assert_instance_of HackerNewsService, service
    
    assert_equal @http_client, service.instance_variable_get(:@http_client)
    assert_equal @broadcasting_service, service.instance_variable_get(:@broadcasting_service)
    assert_equal @logger, service.instance_variable_get(:@logger)
  end


  test "should return stories from cache when valid" do
    cached_stories = [
      { 'id' => 123, 'title' => 'Test Story 1', 'time' => Time.current.to_i },
      { 'id' => 124, 'title' => 'Test Story 2', 'time' => Time.current.to_i - 100 }
    ]
    
    @cache_repository.define_singleton_method(:read) { |key| 
      key == 'top_stories' ? cached_stories : nil 
    }
    @cache_repository.define_singleton_method(:exist?) { |key| 
      key == 'top_stories_is_updated' 
    }
    
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )

    result = service.get_top_stories
    
    assert_equal cached_stories, result
    assert_same cached_stories, result
  end

  test "should fetch new stories when cache is invalid" do
    api_response = [12345, 67890]
    
    @cache_repository.define_singleton_method(:read) { |key| nil }
    @cache_repository.define_singleton_method(:exist?) { |key| false }
    
    @http_client.define_singleton_method(:get) do |url|
      case url
      when '/topstories.json'
        api_response
      when '/item/12345.json'
        { 'id' => 12345, 'title' => 'Fresh Story 1', 'time' => Time.current.to_i, 'kids' => [] }
      when '/item/67890.json'
        { 'id' => 67890, 'title' => 'Fresh Story 2', 'time' => Time.current.to_i - 50, 'kids' => [] }
      end
    end
    
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )
    
    result = service.get_top_stories
    
    assert_not_nil result
    assert result.length >= 1
    assert_equal 'Fresh Story 1', result.first['title']
  end

  test "should handle empty cache gracefully" do
    @cache_repository.define_singleton_method(:read) { |key| nil }
    @cache_repository.define_singleton_method(:exist?) { |key| false }
    
    @http_client.define_singleton_method(:get) do |url|
      case url
      when '/topstories.json'
        [99999]
      when '/item/99999.json'
        { 'id' => 99999, 'title' => 'New Story from API', 'time' => Time.current.to_i, 'kids' => [] }
      end
    end
    
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )
    
    result = service.get_top_stories
    
    assert_not_nil result
    assert_instance_of Array, result
    assert_equal 1, result.length
    assert_equal 'New Story from API', result.first['title']
  end

  test "should search stories by query case insensitive" do
    cached_stories = [
      { 'id' => 1, 'title' => 'JavaScript Frameworks' },
      { 'id' => 2, 'title' => 'Python Machine Learning' },
      { 'id' => 3, 'title' => 'Ruby on Rails Guide' },
      { 'id' => 4, 'title' => 'React Development' }
    ]
    
    @cache_repository.define_singleton_method(:read) { |key| 
      key == 'stories' ? cached_stories : nil 
    }
    @cache_repository.define_singleton_method(:exist?) { |key| 
      key == 'stories_is_updated' 
    }
    
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )
    
    result_lowercase = service.search_stories('javascript')
    result_uppercase = service.search_stories('PYTHON')
    result_mixed = service.search_stories('RuBy')
    
    assert_equal 1, result_lowercase.length
    assert_equal 'JavaScript Frameworks', result_lowercase.first['title']
    
    assert_equal 1, result_uppercase.length
    assert_equal 'Python Machine Learning', result_uppercase.first['title']
    
    assert_equal 1, result_mixed.length
    assert_equal 'Ruby on Rails Guide', result_mixed.first['title']
  end

  test "should limit search results correctly" do
    cached_stories = Array.new(15) do |i|
      { 'id' => i + 1, 'title' => "React Story #{i + 1}" }
    end
    
    @cache_repository.define_singleton_method(:read) { |key| 
      key == 'stories' ? cached_stories : nil 
    }
    @cache_repository.define_singleton_method(:exist?) { |key| 
      key == 'stories_is_updated' 
    }
    
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )
    
    result_default = service.search_stories('react')
    result_limited = service.search_stories('react', 5)
    result_large_limit = service.search_stories('react', 20)
    
    assert_equal 10, result_default.length
    assert_equal 5, result_limited.length
    assert_equal 15, result_large_limit.length
  end

  test "should return empty array when no results found" do
    cached_stories = [
      { 'id' => 1, 'title' => 'JavaScript Frameworks' },
      { 'id' => 2, 'title' => 'Python Machine Learning' },
      { 'id' => 3, 'title' => 'Ruby on Rails Guide' }
    ]
    
    @cache_repository.define_singleton_method(:read) { |key| 
      key == 'stories' ? cached_stories : nil 
    }
    @cache_repository.define_singleton_method(:exist?) { |key| 
      key == 'stories_is_updated' 
    }
    
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )
    
    result = service.search_stories('nonexistent')
    
    assert_not_nil result
    assert_instance_of Array, result
    assert_equal 0, result.length
    assert_empty result
  end

  test "should update cache when max_item_id changed" do
    @cache_repository.define_singleton_method(:read) do |key|
      case key
      when 'max_item_id'
        12345
      else
        nil
      end
    end
    
    @http_client.define_singleton_method(:get) do |url|
      case url
      when '/maxitem.json'
        67890
      when '/topstories.json'
        [11111]
      when '/item/11111.json'
        { 'id' => 11111, 'title' => 'Updated Story', 'time' => Time.current.to_i, 'kids' => [] }
      end
    end
    
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )
    
    result = service.update_cache
    
    assert result[:updated?]
    assert_equal 1, @broadcasting_service.broadcast_count
    assert_not_nil @broadcasting_service.last_broadcast
  end

  test "should not update cache when max_item_id is same" do
    same_id = 12345
    
    @cache_repository.define_singleton_method(:read) do |key|
      case key
      when 'max_item_id'
        same_id
      else
        nil
      end
    end
    
    @http_client.define_singleton_method(:get) do |url|
      case url
      when '/maxitem.json'
        same_id
      end
    end
    
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )
    
    result = service.update_cache
    
    assert_not result[:updated?]
    assert_equal 0, @broadcasting_service.broadcast_count
  end

  test "should return max_item_id when api responds correctly" do
    expected_id = 99999
    
    @http_client.define_singleton_method(:get) do |url|
      case url
      when '/maxitem.json'
        expected_id
      end
    end
    
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )
    
    result = service.send(:fetch_max_item_id)
    
    assert_equal expected_id, result
  end

  test "should return nil when api fails in fetch_max_item_id" do
    @http_client.define_singleton_method(:get) do |url|
      raise StandardError, "Network error"
    end
    
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )
    
    result = service.send(:fetch_max_item_id)
    
    assert_nil result
  end

  test "should fetch and process top stories correctly" do
    @http_client.define_singleton_method(:get) do |url|
      case url
      when '/topstories.json'
        [111, 222, 333]
      when '/item/111.json'
        { 'id' => 111, 'title' => 'Story 1', 'time' => 1000, 'kids' => [] }
      when '/item/222.json'
        { 'id' => 222, 'title' => 'Story 2', 'time' => 2000, 'kids' => [] }
      when '/item/333.json'
        { 'id' => 333, 'title' => 'Story 3', 'time' => 1500, 'kids' => [] }
      end
    end
    
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )
    
    result = service.send(:update_top_stories_cache)
    
    assert_equal 3, result.length
    assert_equal 'Story 2', result[0]['title']
    assert_equal 'Story 3', result[1]['title'] 
    assert_equal 'Story 1', result[2]['title']
  end

  test "should return true for comments with enough words" do
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )
    
    long_comment = {
      'text' => 'This is a very long comment with many words that should definitely pass the minimum word count requirement for valid comments in the system'
    }
    
    result = service.send(:comment_has_enough_words?, long_comment)
    
    assert result
  end

  test "should return false for comments with few words" do
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )
    
    short_comment = {
      'text' => 'Short comment'
    }
    
    result = service.send(:comment_has_enough_words?, short_comment)
    
    refute result
  end

  test "should handle comments with html tags" do
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )
    
    html_comment = {
      'text' => '<p>This is a comment with <strong>HTML tags</strong> that should be <em>stripped</em> when counting words for validation purposes in our system</p>'
    }
    
    result = service.send(:comment_has_enough_words?, html_comment)
    
    assert result
  end

  test "should return false for comments without text" do
    service = HackerNewsService.new(
      http_client: @http_client,
      cache_repository: @cache_repository,
      broadcasting_service: @broadcasting_service,
      logger: @logger
    )
    
    empty_comment = { 'id' => 123 }
    
    result = service.send(:comment_has_enough_words?, empty_comment)
    
    refute result
  end

  private


  def mock_http_client
    http_client = Object.new
    http_client.define_singleton_method(:get) { |url| {} }
    http_client
  end

  def mock_cache_repository
    cache_repository = Object.new
    
    cache_repository.define_singleton_method(:read) { |key| nil }
    cache_repository.define_singleton_method(:write) { |key, value, options = {}| true }
    cache_repository.define_singleton_method(:exist?) { |key| false }
    cache_repository.define_singleton_method(:delete) { |key| true }
    
    cache_repository
  end

  def mock_broadcasting_service
    broadcasting_service = Object.new
    broadcasting_service.extend(MockBroadcastable)
    broadcasting_service.instance_variable_set(:@broadcasted_stories, [])
    broadcasting_service
  end

  def mock_logger
    logger = Object.new
    logger.define_singleton_method(:debug) { |message| nil }
    logger.define_singleton_method(:info) { |message| nil }
    logger.define_singleton_method(:warn) { |message| nil }
    logger.define_singleton_method(:error) { |message| nil }
    
    logger
  end
end
