class CachedApi
  def initialize(cache_repository:)
    @cache_repository = cache_repository
  end

  def load_cache(key, revalidate_fn:)
    data = @cache_repository.read(key)

    if (cache_is_valid?(key))
      return data
    end

    if data.nil?
      Rails.logger.info "🌐 Cache miss - fetching fresh data for key '#{key}'..."
      data = revalidate_fn.call
    elsif !@cache_repository.exist?("#{key}_lock")
      @cache_repository.write("#{key}_lock", true, expires_in: 3.minutes)

      Thread.new do
        begin
          Rails.logger.info "🔄 Cache stale - refreshing data for key '#{key}' in background..."
          revalidate_fn.call
          Rails.logger.info "🔓 Cache refresh finished for key '#{key}', releasing lock"
        rescue => error
          Rails.logger.error "❌ Background refresh failed for '#{key}': #{error.class} #{error.message}"
        ensure
          @cache_repository.delete("#{key}_lock")
        end
      end
    end

    return data
  end

  def save_cache(key, stories, expiration)
    Rails.logger.debug "💾 Saving #{stories.size} items to cache..."

    @cache_repository.write(key, stories)
    @cache_repository.write("#{key}_is_updated", true, expires_in: expiration)

    Rails.logger.debug "✅ Cache saved successfully for key '#{key}'"
  end

  def cache_is_valid?(key)
    @cache_repository.exist?(key) && @cache_repository.exist?("#{key}_is_updated")
  end
end
