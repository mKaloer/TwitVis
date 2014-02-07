require 'twitter'
require 'rserve/simpler'
require 'fileutils'

class TwitterMiner

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  # Output file dimensions.
  OUTPUT_WIDTH = 4
  OUTPUT_HEIGHT = 2.5
  # Tweet point size/alpha.
  POINT_SIZE = 0.2
  POINT_ALPHA = 0.5
  # Time to live in seconds.
  TWEET_LIFE_TIME = 600
  # Delay between plots in seconds.
  PLOT_DELAY = 10

  @buffer
  @client
  @rserve
  @plot_index
  @output_dir

  # Visualize real time tweet locations to given output dir.
  def visualize_real_time_topics(auth, topics, output_dir = "plots")
    rserve_setup
    @output_dir = output_dir
    FileUtils.mkdir_p output_dir
    @buffer = Array.new
    @client = Twitter::Streaming::Client.new do |config|
      config.consumer_key        = auth[:consumer_key]
      config.consumer_secret     = auth[:consumer_secret]
      config.access_token        = auth[:access_token]
      config.access_token_secret = auth[:access_token_secret]
    end
    
    stream = Thread.new { listen_for_tweets(topics) }
    @plot_index = 0
    # Visualize while streaming
    while stream.alive?
      @plot_index += 1 if plot_tweet_locations
      sleep PLOT_DELAY
    end
  end
  
  # Visualize locations of historical tweets of topic.
  def visualize_historical_topics(auth, query, num_results = 100,
                                  output_dir = "plots")
    rserve_setup
    @output_dir = output_dir
    FileUtils.mkdir_p output_dir
    @buffer = Array.new
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = auth[:consumer_key]
      config.consumer_secret     = auth[:consumer_secret]
      config.access_token        = auth[:access_token]
      config.access_token_secret = auth[:access_token_secret]
    end
    
    @plot_index = 0
    max_id = 0
    # Keep requesting until the number of tweets have been found.
    while @buffer.length < num_results do
      options = 
        {
          count: 100
        }
      options[:max_id] = max_id if max_id > 0
      begin
        result = @client.search(query, options)
        result.each do |tweet|
          # Stop if all tweets are registered.
          break if @buffer.length >= num_results
      
          if tweet.is_a?(Twitter::Tweet) and not tweet.place.nil?
            @buffer << { tweet: tweet, ttl: tweet.created_at + TWEET_LIFE_TIME }
            # Print status
            print "#{@buffer.length}/#{num_results}\r"
            $stdout.flush
          end
        end
      rescue Twitter::Error::TooManyRequests
        print "Rate limit exceeded. Sleeping...\r"
        $stdout.flush
        sleep(30)
      end
      # Set new max id
      max_id = @buffer.last[:tweet].id if not @buffer.last.nil?
    end
    
    puts "Exporting..."
    # Visualize
    len = @buffer.length
    @buffer.each_with_index do |tweet,i|
      @plot_index += 1 if plot_tweet_locations(tweet[:tweet].created_at)
      print "#{i}/#{len} \r"
      $stdout.flush
    end
  end

  private

  # Connects to rserve and sets it working directory.
  def rserve_setup
    # Connect to Rserve and verify connection
    @rserve = Rserve::Simpler.new
    v = @rserve.eval("R.version.string");
    puts "Connected to #{v.as_string}"
    # Set working directory.
    @rserve.eval("setwd('#{Dir.pwd}')")
    contents = File.read('plot.R')
    @rserve.eval(contents)
  end

  # Real-time analysis.
  def listen_for_tweets(topics)
    @client.filter(:track => topics.join(",")) do |object|
      if object.is_a?(Twitter::Tweet) and not object.place.nil?
        @buffer << { tweet: object, ttl: Time.now + TWEET_LIFE_TIME }
        puts object.text
      end
    end
  end
  
  # History analysi.
  def search_tweets(topics)
    @client.filter(:track => topics.join(",")) do |object|
      if object.is_a?(Twitter::Tweet) and not object.place.nil?
        @buffer << { tweet: object, ttl: Time.now + TWEET_LIFE_TIME }
        puts object.text
      end
    end
  end

  # Plots tweet locations. Returns true if plot created, otherwise false.
  def plot_tweet_locations(to_time = Time.now)

    # Remove old elements from buffer
    while !@buffer.empty? and @buffer.first[:ttl] < Time.now do
      @buffer.shift
    end
    return false if @buffer.empty?

    data = Hash[:lat, Array.new(0), :long, Array.new(0)]
    @buffer.each do |tweet|
      data[:lat] << tweet[:tweet].place.bounding_box.coordinates[0][0][0]
      data[:long] << tweet[:tweet].place.bounding_box.coordinates[0][0][1]
    end

    df = Rserve::DataFrame.new(data)
    @rserve.command( df: df ) do 
      %Q{
        ggsave('#{File.join(@output_dir, "world_#{@plot_index}.png")}',
                plotworld(df, #{POINT_SIZE}, #{POINT_ALPHA}),
                width=#{OUTPUT_WIDTH},
                height=#{OUTPUT_HEIGHT}
              )
      }
    end
    return true
  end


end
