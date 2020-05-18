class TwitterController < ApplicationController

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
    @user_timeline = rest_client.user_timeline("NiallOfficial").take(20).reverse
    index = 0
    last_data_time = TweetTime.last.tweet_created_at
    last_tweet_time = @user_timeline.last.created_at
    @user_timeline.each do |tweet|
      text_without_auto_url = tweet.text.gsub(/http(s|):[\/\w\-\_\.\!\*\'\)\(]+/, "")
      if last_data_time < tweet.created_at
        unless tweet.reply?
          if tweet.retweet?
              rest_client.update("#{tweet.retweeted_status.text.gsub(/http(s|):[\/\w\-\_\.\!\*\'\)\(]+/, "")} RT from #{tweet.user.name} twitter.com/#{tweet.retweeted_status.user.screen_name}/status/#{tweet.retweeted_status.id}")

          elsif tweet.truncated?
            if tweet.quote?
              rest_client.update("#{text_without_auto_url} #{tweet.url}")
            else
              rest_client.update("#{text_without_auto_url} #{tweet.url}")
            end
            
          else
            if tweet.quote?
              rest_client.update("#{tweet.text}")
            else
              rest_client.update("#{tweet.text} #{tweet.url}")
            end
          end
        end
      end
      index += 1
    end
    if last_data_time < last_tweet_time
      TweetTime.create(tweet_created_at: last_tweet_time)
    end
    render plain: index
  end




  def single_tweet
    tweet = set_rest_client.status(1261739539384713217)
    set_rest_client.update("#{tweet.text} #{tweet.url}")
    TweetTime.create(tweet_created_at: tweet.created_at)
    render plain: "#{tweet.text}\n#{tweet.url}"
  end

  def check_phenomenon
    tweet = set_rest_client.user_timeline("joerogan").take(5).reverse
    if TweetTime.last.tweet_created_at < tweet[3].created_at
      TweetTime.create(tweet_created_at: tweet.last.created_at)
    end
    render plain: "#{TweetTime.last.tweet_created_at < tweet[3].created_at}"
  end
  

  def check_methods
    @check = TweetTime.new.create
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

end
