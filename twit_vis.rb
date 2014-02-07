require 'yaml'
require 'optparse'
require_relative 'twitter_miner.rb'

options = {}
OptionParser.new do |opts|
  options[:output] = "plots"
  options[:real_time] = true
  
  opts.on("-t", "--topics X,Y,Z", Array, "The topics to analyze") do |list|
    options[:topics] = list
  end
  
  opts.on("-o", "--output [OUTPUT_DIR]","The output image output directory") do |out|
    options[:output] = out
  end
  
  opts.on("-r", "--realtime","If set, a real time analysis will be performed") do |rt|
    options[:real_time] = true
  end
  
  opts.on("-h", "--historical","If set, a historical time analysis will be performed") do |rt|
    options[:historical] = true
  end
  
  opts.on_tail("-h", "--help", "Show help") do
    puts opts
    exit
  end
end.parse!

if options[:topics].nil?
  puts "Missing argument -t: Topics required. Use -h for help."
  exit
end

# Create an auth.yml file with your Twitter api keys:

#:consumer_key: YOUR_CONSUMER_KEY_HERE
#:consumer_secret: YOUR_CONSUMER_SECRET_HERE
#:access_token: YOUR_ACCESS_TOKEN_HERE
#:access_token_secret: YOUR_ACCESS_TOKEN_SECRET_HERE
auth = YAML::load(File.open('auth.yml'))

twitter = TwitterMiner.new

if options[:historical]
  twitter.visualize_historical_topics(auth, options[:topics].join(","), 100, options[:output])
else
  twitter.visualize_real_time_topics(auth, options[:topics], options[:output])
end