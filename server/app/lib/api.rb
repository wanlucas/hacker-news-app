require 'net/http'
require 'json'

class Api
  class ApiError < StandardError; end

  attr_reader :base_url

  def initialize(base_url)
    @base_url = base_url
  end

  def get(endpoint)
    uri = URI("#{base_url}#{endpoint}")
    response = Net::HTTP.get_response(uri)
    
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      Rails.logger.error "Request error: #{response.code} - #{response.message}"
      raise ApiError, "API request failed with status #{response.code} - #{response.message}"
    end
  end
end
