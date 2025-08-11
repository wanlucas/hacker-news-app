class CachedApi < Api
  def initialize(base_url)
    super(base_url)
  end

  def load_cache(key, revalidate_fn:)
    data = Rails.cache.read(key)

    if (cache_is_valid?(key))
      return data
    end

    if data.nil?
      Rails.logger.info "🌐 Cache miss - fetching fresh data for key '#{key}'..."
      data = revalidate_fn.call
    elsif !Rails.cache.exist?("#{key}_lock")
      Rails.cache.write("#{key}_lock", true, expires_in: 3.minutes)

      Thread.new do
        begin
          Rails.logger.info "🔄 Cache stale - refreshing data for key '#{key}' in background..."
          revalidate_fn.call
          Rails.logger.info "🔓 Cache refresh finished for key '#{key}', releasing lock"
        rescue => error
          Rails.logger.error "❌ Background refresh failed for '#{key}': #{error.class} #{error.message}"
        ensure
          Rails.cache.delete("#{key}_lock")
        end
      end
    end

    return data
  end

  def save_cache(key, stories, expiration)
    Rails.logger.debug "💾 Saving #{stories.size} items to cache..."

    Rails.cache.write(key, stories)
    Rails.cache.write("#{key}_is_updated", true, expires_in: expiration)

    Rails.logger.debug "✅ Cache saved successfully for key '#{key}'"
  end

  def cache_is_valid?(key)
    Rails.cache.exist?(key) && Rails.cache.exist?("#{key}_is_updated")
  end
end
