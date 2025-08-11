module Repositories
  module Cache
    class Memory < Base
      def initialize
        @data = {}
        @mutex = Mutex.new
      end

      def read(key)
        key_str = key.to_s
        @mutex.synchronize do
          puts(@data[key_str], @data)
          return nil unless @data.key?(key_str)
          
          entry = @data[key_str]
          if expired?(key_str)
            @data.delete(key_str)
            return nil
          end
          
          entry[:value]
        end
      end

      def write(key, value, options = {})
        expires_in = options[:expires_in]
        key_str = key.to_s
        
        @mutex.synchronize do
          @data[key_str] = {
            value: value,
            expires_at: expires_in ? Time.current + expires_in : nil
          }
        end
        
        puts(@data[key_str], @data)
        value
      end

      def exist?(key)
        key_str = key.to_s
        @mutex.synchronize do
          @data.key?(key_str) && !expired?(key_str)
        end
      end

      def delete(key)
        key_str = key.to_s
        @mutex.synchronize do
          @data.delete(key_str)
        end
      end

      def fetch(key, options = {})
        key_str = key.to_s

        if exist?(key_str)
          read(key_str)
        elsif block_given?
          value = yield
          write(key_str, value, options)
          value
        else
          nil
        end
      end

      private

      def expired?(key)
        return false unless @data.key?(key)
        
        expires_at = @data[key][:expires_at]
        expires_at && Time.current > expires_at
      end
    end
  end
end
