class HackerNewsService < Api
  MAX_TOP_STORIES = 4
  MAX_NEW_STORIES = 1
  MIN_COMMENT_WORDS = 20

  def self.instance
    @instance ||= new("https://hacker-news.firebaseio.com/v0")
  end

  def get_top_stories
    cached_stories = Rails.cache.read('top_stories')

    if cached_stories
      Rails.logger.debug "📖 Returning #{cached_stories.size} stories from cache"
      return cached_stories
    end

    Rails.logger.info "🌐 Cache miss - fetching fresh stories from API..."
    update_top_stories_cache
  end

  def search_stories(query, limit = 10)
    cached_stories = Rails.cache.read('new_stories')

    if !cached_stories
      Rails.logger.info "🌐 Cache miss - fetching fresh stories from API..."
      cached_stories = update_new_stories_cache
    end

    Rails.logger.debug "📖 Returning #{cached_stories.size} stories from cache"

    cached_stories
      .select { |story| story['title'].downcase.include?(query.downcase) }
      .take(limit)
  end

  def update_top_stories_cache(limit = MAX_TOP_STORIES)
    start_time = Time.current

   
    response = get('/topstories.json')
    ids = response.is_a?(Array) ? response : []
    stories = fetch_stories_by_ids(ids.take(limit))

    Rails.logger.debug "📋 Found #{stories.size} top stories"

    valid_stories = filter_valid_stories(stories)
    save_cache('top_stories', valid_stories)

    duration = Time.current - start_time
    Rails.logger.info "✅ Cache updated successfully with #{valid_stories.size} stories in #{duration.round(2)}s"

    valid_stories
  end

  def update_new_stories_cache(limit = MAX_NEW_STORIES)
    start_time = Time.current

    response = get('/newstories.json')

    ids = response.is_a?(Array) ? response : []
    Rails.logger.debug "📊 API returned #{ids.size} story IDs"
    stories = fetch_stories_by_ids(ids.take(limit))

    Rails.logger.debug "📋 Found #{stories.size} new stories"
    valid_stories = filter_valid_stories(stories)

    save_cache('new_stories', valid_stories)

    duration = Time.current - start_time
    Rails.logger.info "✅ Cache updated successfully with #{valid_stories.size} stories in #{duration.round(2)}s"

    valid_stories
  end

  def cache_needs_update?
    max_item_id = fetch_max_item_id

    if Rails.cache.read('max_item_id') == max_item_id
      Rails.logger.debug "🔄 Cache is up-to-date with max item ID #{max_item_id}"
      return false
    end

    last_update = Rails.cache.read('cache_last_update')
    story_count = Rails.cache.read('top_stories')&.size || 0

    story_count == 0 || (last_update && last_update < 10.minutes.ago)
  end

  private

  def fetch_max_item_id
    get('/maxitem.json')
  rescue Api::ApiError => error
    Rails.logger.error "❌ Failed to fetch max item ID: #{error.message}, returning infinity"
    Float::INFINITY
  end

  def fetch_stories_by_ids(ids)
    Rails.logger.debug "⚡ Starting parallel fetch for #{ids.size} stories..."

    stories = []
    mutex = Mutex.new

    ids.each_slice(5) do |batch|
      Rails.logger.debug "📦 Processing batch of #{batch.size} stories..."

      threads = batch.map do |id|
        Thread.new do
          begin
            story = get_story(id)

            if story
              comments = fetch_comments(story['kids'] || [])
              story['comments'] = comments
              story.delete('kids')

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

  def filter_valid_stories(stories)
    valid = stories.compact.select do |story|
      !story['deleted']
    end

    Rails.logger.debug "✅ Filtered to #{valid.size} valid stories"
    valid
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

  def save_cache(key, stories)
    Rails.logger.debug "💾 Saving #{stories.size} stories to cache..."

    max_item_id = fetch_max_item_id

    Rails.cache.write('max_item_id', max_item_id) if max_item_id != Float::INFINITY
    Rails.cache.write(key, stories)

    Rails.logger.debug "✅ Cache saved successfully for key '#{key}'"
  end
end

