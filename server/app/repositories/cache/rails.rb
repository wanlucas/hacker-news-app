module Cache
  class Rails < Base
    def initialize(cache_store = ::Rails.cache)
      @cache_store = cache_store
    end

    def read(key)
      @cache_store.read(key)
    end

    def write(key, value, options = {})
      @cache_store.write(key, value, options)
    end

    def exist?(key)
      @cache_store.exist?(key)
    end

    def delete(key)
      @cache_store.delete(key)
    end

    def fetch(key, options = {}, &block)
      @cache_store.fetch(key, options, &block)
    end
  end
end
