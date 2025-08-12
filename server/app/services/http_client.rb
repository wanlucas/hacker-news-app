class HttpClient
  require 'net/http'
  require 'json'

  class ApiError < StandardError; end

  def initialize(base_url)
    @base_url = base_url
  end

  def get(endpoint)
    uri = URI("#{@base_url}#{endpoint}")
    response = Net::HTTP.get_response(uri)
    
    Rails.logger.debug "🌐 Request to #{uri} returned #{response.code}"
    
    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      Rails.logger.debug "📦 Parsed response: #{result.class} - #{result.inspect[0..100]}"
      result
    else
      Rails.logger.error "Request error: #{response.code} - #{response.message}"
      raise ApiError, "API request failed with status #{response.code} - #{response.message}"
    end
  rescue JSON::ParserError => e
    Rails.logger.error "JSON parse error: #{e.message}"
    raise ApiError, "Failed to parse JSON response: #{e.message}"
  rescue => e
    Rails.logger.error "HTTP request error: #{e.message}"
    raise ApiError, "HTTP request failed: #{e.message}"
  end
end