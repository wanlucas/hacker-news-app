class HackerNewsService < CachedApi
  MAX_TOP_STORIES = 2
  MAX_STORIES = 1
  MIN_COMMENT_WORDS = 20

  def initialize(cache_repository:)
    super('https://hacker-news.firebaseio.com/v0', cache_repository: cache_repository)
  end

  def get_top_stories
    return load_cache('top_stories', revalidate_fn: method(:update_top_stories_cache))
  end

  def search_stories(query, limit = 10)
    stories = load_cache('stories', revalidate_fn: method(:update_stories_cache))

    stories
      .select { |story| story['title'].downcase.include?(query.downcase) }
      .take(limit)
  end

  def update_cache
    max_item_id = fetch_max_item_id
    act_item_id = @cache_repository.read('max_item_id')

    info = {
      max_item_id: max_item_id,
      top_stories: @cache_repository.read('top_stories')&.size || 0,
      stories: @cache_repository.read('stories')&.size || 0
    }

    if !act_item_id.nil? && max_item_id == act_item_id
      return info
    end

    @cache_repository.write('max_item_id', max_item_id)

    if !cache_is_valid?('top_stories')
      new_stories = update_top_stories_cache
      
      StoriesChannel.broadcast_new_stories(new_stories)
      
      Rails.logger.info "🚀 WebSocket: Novas top stories enviadas para clientes conectados (#{new_stories.size} stories)"
    end

    if !cache_is_valid?('stories')
      update_stories_cache
    end

    info[:top_stories] = @cache_repository.read('top_stories')&.size || 0
    info[:stories] = @cache_repository.read('stories')&.size || 0

    return info
  end

  private

  def update_top_stories_cache(limit = MAX_TOP_STORIES)
    start_time = Time.current

    response = get('/topstories.json')
    ids = response.is_a?(Array) ? response : []
    stories = fetch_stories_by_ids(ids.take(limit))

    Rails.logger.debug "📋 Found #{stories.size} top stories"

    valid_stories = filter_valid_stories(stories)
    save_cache('top_stories', valid_stories, 5.minutes)

    duration = Time.current - start_time
    Rails.logger.info "✅ Cache updated successfully with #{valid_stories.size} stories in #{duration.round(2)}s"

    valid_stories
  end

  def update_stories_cache(limit = MAX_STORIES)
    start_time = Time.current

    response = get('/newstories.json')

    ids = response.is_a?(Array) ? response : []
    Rails.logger.debug "📊 API returned #{ids.size} story IDs"

    stories = fetch_stories_by_ids(ids.take(limit))
    Rails.logger.debug "📋 Found #{stories.size} new stories"

    valid_stories = filter_valid_stories(stories)

    save_cache('stories', valid_stories, 1.minute)

    duration = Time.current - start_time
    Rails.logger.info "✅ Cache updated successfully with #{valid_stories.size} stories in #{duration.round(2)}s"

    valid_stories
  end

  def fetch_max_item_id
    get('/maxitem.json')

  rescue Api::ApiError => error
    Rails.logger.error "❌ Failed to fetch max item ID: #{error.message}, returning nil"
    nil
  end

  def fetch_stories_by_ids(ids)
    Rails.logger.debug "⚡ Starting parallel fetch for #{ids.size} stories..."

    stories = []
    mutex = Mutex.new

    ids.each_slice(10) do |batch|
      Rails.logger.debug "📦 Processing batch of #{batch.size} stories..."

      threads = batch.map do |id|
        Thread.new do
          begin
            story = fetch_story(id)

            if story
              comments = fetch_comments(story['kids'] || [])
              story['comments'] = comments
              story.delete('kids')

              mutex.synchronize { stories << story }
            end
          rescue => error
            Rails.logger.warn "⚠️ Failed to fetch story #{id}: #{error.message}"
          end
        end
      end

      threads.each { |thread| thread.join(15) }
    end

    Rails.logger.debug "📚 Fetched #{stories.size} stories successfully"
    return stories
  end

  def fetch_story(id)
    story = get("/item/#{id}.json")
    story if story && story['type'] == 'story'
  end

  def fetch_comments(ids)
    return [] if ids.nil? || ids.empty?

    comments = []
    mutex = Mutex.new

    ids.each_slice(30) do |batch|
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

    return valid
  end

  def filter_valid_comments(comments)
    valid = comments.compact.select do |comment|
      !comment['deleted'] && comment_has_enough_words?(comment)
    end

    return valid
  end

  def comment_has_enough_words?(comment)
    return false unless comment['text']

    word_count = comment['text']
      .gsub(/<[^>]*>/, ' ')
      .split(/\s+/)
      .reject(&:empty?)
      .size

    return word_count >= MIN_COMMENT_WORDS
  end
end

