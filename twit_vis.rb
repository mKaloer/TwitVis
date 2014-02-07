require 'yaml'
require_relative 'twitter_miner.rb'

# Create an auth.yml file with your Twitter api keys:

#:consumer_key: YOUR_CONSUMER_KEY_HERE
#:consumer_secret: YOUR_CONSUMER_SECRET_HERE
#:access_token: YOUR_ACCESS_TOKEN_HERE
#:access_token_secret: YOUR_ACCESS_TOKEN_SECRET_HERE
auth = YAML::load(File.open('auth.yml'))

twitter = TwitterMiner.new

# Visualize olympc tweets.
topics = ["olympics", "sochi"]
twitter.visualize_real_time_topics(auth, topics)
#twitter.visualize_historical_topics(auth, "olympics", 100)