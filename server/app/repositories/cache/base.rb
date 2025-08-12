module Cache
  class Base
    def read(key)
      raise NotImplementedError, "#{self.class} must implement #read"
    end

    def write(key, value, options = {})
      raise NotImplementedError, "#{self.class} must implement #write"
    end

    def exist?(key)
      raise NotImplementedError, "#{self.class} must implement #exist?"
    end

    def delete(key)
      raise NotImplementedError, "#{self.class} must implement #delete"
    end

    def fetch(key, options = {}, &block)
      raise NotImplementedError, "#{self.class} must implement #fetch"
    end
  end
end
