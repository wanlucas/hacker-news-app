class BroadcastingService
  def broadcast_new_stories(stories)
    StoriesChannel.broadcast_new_stories(stories)
  end
end
