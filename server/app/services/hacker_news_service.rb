class HackerNewsService < CachedApi
  MAX_TOP_STORIES = 1
  MAX_STORIES = 50
  MIN_COMMENT_WORDS = 20

  def initialize(
    http_client:,
    cache_repository:, 
    broadcasting_service:,
    logger:
  )
    super(cache_repository: cache_repository)

    @http_client = http_client
    @broadcasting_service = broadcasting_service
    @logger = logger
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

    if !act_item_id.nil? && max_item_id == act_item_id
      return { updated?: false }
    end

    @cache_repository.write('max_item_id', max_item_id)

    new_stories = update_top_stories_cache
    
    @broadcasting_service.broadcast_new_stories(new_stories)

    # update_stories_cache

    return { updated?: true }
  end

  private

  def update_top_stories_cache(limit = MAX_TOP_STORIES)
    start_time = Time.current

    response = @http_client.get('/topstories.json')
    ids = response.is_a?(Array) ? response : []
    stories = fetch_stories_by_ids(ids.take(limit))
      .sort_by { |story| -(story['time'] || 0) }

    @logger.debug "📋 Found #{stories.size} top stories"


    save_cache('top_stories', stories, 15.minutes)

    duration = Time.current - start_time
    @logger.info "✅ Cache updated successfully with #{stories.size} stories in #{duration.round(2)}s"

    return stories
  end

  def update_stories_cache(limit = MAX_STORIES)
    start_time = Time.current

    response = @http_client.get('/newstories.json')

    ids = response.is_a?(Array) ? response : []
    @logger.debug "📊 API returned #{ids.size} story IDs"

    stories = fetch_stories_by_ids(ids.take(limit))
    @logger.debug "📋 Found #{stories.size} new stories"

    save_cache('stories', stories, 10.minutes)

    duration = Time.current - start_time
    @logger.info "✅ Cache updated successfully with #{stories.size} stories in #{duration.round(2)}s"

    return stories
  end

  def fetch_max_item_id
    @http_client.get('/maxitem.json')

  rescue HttpClient::ApiError => error
    @logger.error "❌ Failed to fetch max item ID: #{error.message}, returning nil"
    nil
  end

  def fetch_stories_by_ids(ids)
    @logger.debug "⚡ Starting parallel fetch for #{ids.size} stories..."

    stories = []
    mutex = Mutex.new

    ids.each_slice(10) do |batch|
      @logger.debug "📦 Processing batch of #{batch.size} stories..."

      threads = batch.map do |id|
        Thread.new do
            story = fetch_story(id)

            if story
              comments = fetch_comments(story['kids'] || [])

              story['comments'] = comments
              story.delete('kids')

              mutex.synchronize { stories << story }
            end
        end
      end

      threads.each(&:join)
    end

    @logger.debug "📚 Fetched #{stories.size} stories successfully"
    return stories.compact
  end

  def fetch_story(id)
    @http_client.get("/item/#{id}.json")
  rescue => error
    @logger.warn "⚠️ Failed to fetch story #{id}: #{error.message}"
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
                comment['comments'] = child_comments
                comment.delete('kids')
              end

              mutex.synchronize { comments << comment }
            end
          rescue => e
            @logger.warn "⚠️ Failed to fetch comment #{id}: #{e.message}"
            nil
          end
        end
      end

      threads.each { |thread| thread.join(10) }
    end

    filter_valid_comments(comments)
  end

  def fetch_comment(id)
    comment = @http_client.get("/item/#{id}.json")
    comment if comment && comment['type'] == 'comment'
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

