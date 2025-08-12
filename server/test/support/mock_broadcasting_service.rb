module MockBroadcastable
  extend ActiveSupport::Concern
  
  included do
    attr_reader :broadcasted_stories
  end

  def initialize(*args)
    @broadcasted_stories = []
  end

  def broadcast_new_stories(stories)
    @broadcasted_stories << stories
  end

  def reset_broadcasts!
    @broadcasted_stories.clear
  end

  def broadcast_count
    @broadcasted_stories.length
  end

  def last_broadcast
    @broadcasted_stories.last
  end
end
