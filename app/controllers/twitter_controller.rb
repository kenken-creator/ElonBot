class TwitterController < ApplicationController

  # before_action :set_rest_client

  def update
    set_rest_client
    @restClient.update("test mk.2")
    render plain: "Twitter.update"
  end

  def get_user
    user_name = set_rest_client.user("elonmusk").screen_name
    render plain: "#{user_name}"
  end

  def stream_text
    rest_client = set_rest_client
    @user_timeline = rest_client.user_timeline("elonmusk").take(20)
    @user_timeline.each do |tweet|
      if tweet.text.start_with?("RT")
        rest_client.update("#{tweet.retweeted_status.text} twitter.com/#{tweet.retweeted_status.user.screen_name}/status/#{tweet.retweeted_status.id}")
      elsif tweet.quote?
        rest_client.update("#{tweet.text}")
      elsif tweet.text.start_with?("@")
        rest_client.update("#{tweet.text.gsub(/@[a-z|A-Z|0-9|_]+/, "")} twitter.com/#{tweet.in_reply_to_screen_name}/status/#{tweet.in_reply_to_status_id}")
      else rest_client.update("#{tweet.text} twitter.com/#{tweet.user.screen_name}/status/#{tweet.id}")
      end
    end
  end

  def single_tweet
    #引用リツイートに関して末尾が丸まった場合https消したいけど、写真・動画もhttpsだからどうしようか。あ、末尾丸まったらリツイートを埋め込めばいいだけだから気にしなくていいかも
    tweet = set_rest_client.status(1261646331006849024)
    unless tweet.text.length == 140 or 139
      set_rest_client.update("#{tweet.text.gsub(/http(s|):[\/\w\-\_\.\!\*\'\)\(]+/, "")} twitter.com/#{tweet.user.screen_name}/status/#{tweet.id}")
    end
    render plain: "#{tweet.text}\n#{tweet.text.gsub(/@[a-z|A-Z|0-9|_]+/, "")}"
  end

  def check_methods
    @check = set_rest_client.status(1255918585991454721).text.methods
  end

  private

  def set_rest_client
    return rest_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = Rails.application.credentials[:twitter][:API_key]
      config.consumer_secret     = Rails.application.credentials[:twitter][:API_secret]
      config.access_token        = Rails.application.credentials[:twitter][:access_token]
      config.access_token_secret = Rails.application.credentials[:twitter][:access_token_secret]
    end
  end

  def set_streaming_client
    @streamingClient = Twitter::Streaming::Client.new do |config|
      config.consumer_key        = Rails.application.credentials[:twitter][:API_key]
      config.consumer_secret     = Rails.application.credentials[:twitter][:API_secret]
      config.access_token        = Rails.application.credentials[:twitter][:access_token]
      config.access_token_secret = Rails.application.credentials[:twitter][:access_token_secret]
    end
  end
end
