require 'yaml'
require 'twitter'

auth = YAML::load(File.open('auth.yml'))

client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = auth['consumer_key']
  config.consumer_secret     = auth['consumer_secret']
  config.access_token        = auth['access_token']
  config.access_token_secret = auth['access_token_secret']
end