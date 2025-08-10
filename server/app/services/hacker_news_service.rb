class HackerNewsService < Api
  MAX_TOP_STORIES = 1
  MIN_COMMENT_WORDS = 20

  def self.instance
    @instance ||= new("https://hacker-news.firebaseio.com/v0")
  end
  
  def get_top_stories(limit = 15)
    cached_stories = Rails.cache.read('top_stories')

    if cached_stories
      Rails.logger.debug "📖 Returning #{cached_stories.size} stories from cache"
      return cached_stories.take(limit)
    end

    Rails.logger.info "🌐 Cache miss - fetching fresh stories from API..."

    update_top_stories_cache.take(limit)
  end
  
  def update_top_stories_cache
    Rails.logger.info "🔄 Starting fresh data fetch from Hacker News API..."

    start_time = Time.current
    
    begin
      stories = fetch_top_stories(MAX_TOP_STORIES)

      Rails.logger.debug "📋 Found #{stories.size} top stories"

      valid_stories = filter_valid_stories(stories)

      save_cache(valid_stories)

      duration = Time.current - start_time
      Rails.logger.info "✅ Cache updated successfully with #{valid_stories.size} stories in #{duration.round(2)}s"
      
      valid_stories
      
    rescue => error
      Rails.logger.error "❌ Unexpected error during cache update: #{error.class} - #{error.message}"
      handle_unexpected_error(error)
    end
  end
  
  def cache_needs_update?
    max_item_id = fetch_max_item_id

    if Rails.cache.read('max_item_id') == max_item_id
      Reails.logger.debug "🔄 Cache is up-to-date with max item ID #{max_item_id}"
      return false
    end

    last_update = Rails.cache.read('cache_last_update')
    story_count = Rails.cache.read('top_stories')&.size || 0
    
    story_count == 0 || (last_update && last_update < 10.minutes.ago)
  end

  private

  def fetch_max_item_id
    get('/maxitem.json?print')

  rescue Api::ApiError => error
    Rails.logger.error "❌ Failed to fetch max item ID: #{error.message}, returning infinity"
    Float::INFINITY
  end

  def fetch_top_stories(limit)
    Rails.logger.debug "⚡ Starting parallel fetch for #{limit} stories..."

    response = get('/topstories.json')
    
    ids = response.is_a?(Array) ? response : []
    Rails.logger.debug "📊 API returned #{ids.size} story IDs"
    
    stories = []
    mutex = Mutex.new
    
    ids.take(limit).each_slice(5) do |batch|
      Rails.logger.debug "📦 Processing batch of #{batch.size} stories..."

      threads = batch.map do |id|
        Thread.new do
          begin
            story = get_story(id)
            comments = fetch_comments(story['kids'] || [])

            story['comments'] = comments
  
            story.delete('kids')
  
            if story
              mutex.synchronize { stories << story }
            end
          rescue => e
            Rails.logger.warn "⚠️ Failed to fetch story #{id}: #{e.message}"
          end
        end
      end
      
      threads.each { |thread| thread.join(15) }
    end
    
    Rails.logger.debug "📚 Fetched #{stories.size} stories successfully"
    stories
  end
  
  def get_story(id)
    story = get("/item/#{id}.json")
    story if story && story['type'] == 'story'
  end

  def filter_valid_stories(stories)
    valid = stories.compact.select do |story|
      !story['deleted']
    end
    
    Rails.logger.debug "✅ Filtered to #{valid.size} valid stories"
    valid
  end

  def fetch_comments(ids)
    Rails.logger.debug "🔍 Fetching comments for #{ids.size} IDs..."

    return [] if ids.nil? || ids.empty?

    comments = []
    mutex = Mutex.new
     
     ids.each_slice(20) do |batch|
      Rails.logger.debug "📦 Fetching comments for batch of #{batch.size} IDs..."
      
      threads = batch.map do |id|
        Thread.new do
          begin
            comment = fetch_comment(id)

            if comment
              if comment['kids'] && !comment['kids'].empty?
                child_comments = fetch_comments(comment['kids'])
                valid_child_comments = filter_valid_comments(child_comments)
                comment['comments'] = valid_child_comments
                comment.delete('kids')
              end

              mutex.synchronize { comments << comment }
            end
          rescue => e
            Rails.logger.warn "⚠️ Failed to fetch comment #{id}: #{e.message}"
            nil
          end
        end
      end
      
      threads.each { |thread| thread.join(15) }
    end

    Rails.logger.debug "📚 Fetched #{comments.size} comments successfully"
      filter_valid_comments(comments)
  end

  def fetch_comment(id)
    comment = get("/item/#{id}.json")
    comment if comment && comment['type'] == 'comment'
  end

  def filter_valid_comments(comments)
    valid = comments.compact.select do |comment|
      !comment['deleted'] && comment_has_enough_words?(comment)
    end
    
    Rails.logger.debug "✅ Filtered to #{valid.size} valid comments"
    valid
  end
  
  def comment_has_enough_words?(comment)
    return false unless comment['text']

    word_count = comment['text']
      .gsub(/<[^>]*>/, ' ')
      .split(/\s+/)
      .reject(&:empty?)
      .size
    
    word_count >= MIN_COMMENT_WORDS
  end
  
  def save_cache(stories)
    Rails.logger.debug "💾 Saving #{stories.size} stories to cache..."

    max_item_id = fetch_max_item_id

    Rails.cache.write('max_item_id', max_item_id) if max_item_id != Float::INFINITY
    Rails.cache.write('top_stories', stories)
    Rails.cache.write('cache_last_update', Time.current)
    Rails.cache.write('cache_story_count', stories.size)
    
    Rails.logger.debug "✅ Cache saved successfully"
  end
  
  def handle_unexpected_error(error)
  
    cached = Rails.cache.read('top_stories')

    if cached.present?
      Rails.logger.warn "🔄 Returning #{cached.size} cached stories due to error"
      return cached
    end
    
    raise Api::ApiError, "No cache available and API failed"
  end
end

