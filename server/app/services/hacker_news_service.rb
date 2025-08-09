class HackerNewsService < Api
  def self.instance
    @instance ||= new("https://hacker-news.firebaseio.com/v0")
  end

  def self.get_story(id)
    instance.get("/item/#{id}.json")
  end

  def self.get_top_story_ids(limit = 15)
    response = instance.get('/topstories.json')
    response.take(limit)
  end

  def self.find_stories_by_ids(ids)
    return [] if ids.nil? || ids.empty?
    
    threads = []
    stories = []

    ids.each do |id|
      threads << Thread.new do
        story = get_story(id)
        Thread.current[:result] = story
      end
    end
    
    threads.each do |thread|
      thread.join(10)
      stories << thread[:result] if thread[:result]
    end

    stories.compact
  end
end

