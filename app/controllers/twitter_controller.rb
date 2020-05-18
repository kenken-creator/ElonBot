class TwitterController < ApplicationController

  def update
    set_twitter_api
    @restClient.update("test mk.2")
    render plain: "Twitter.update"
  end

  def get_user
    user_name = set_twitter_api.user("elonmusk").screen_name
    render plain: "#{user_name}"
  end



  def stream_text
    #set_twitter_api自体がrest_clientを定義してるから,一行目はset_twitter_apiだけでいいかも
    rest_client = set_twitter_api
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
    tweet = set_twitter_api.status(1261739539384713217)
    set_twitter_api.update("#{tweet.text} #{tweet.url}")
    TweetTime.create(tweet_created_at: tweet.created_at)
    render plain: "#{tweet.text}\n#{tweet.url}"
  end

  def check_phenomenon
    tweet = set_twitter_api.user_timeline("joerogan").take(5).reverse
    if TweetTime.last.tweet_created_at < tweet[3].created_at
      TweetTime.create(tweet_created_at: tweet.last.created_at)
    end
    render plain: "#{TweetTime.last.tweet_created_at < tweet[3].created_at}"
  end

  def translate
    endpoint = set_translate_api
    tweet = set_twitter_api.user_timeline('digitalps').take(10)
    #Tweetの本文を翻訳APIにかける
    url = "https://mt-auto-minhon-mlt.ucri.jgn-x.jp/api/mt/generalNT_en_ja/"
    translate_key = Rails.application.credentials[:nict][:translate_key]
    name = 'kenkenchi'
    tweet.each do |tweet|
      response = endpoint.post(url,{key: translate_key, name: name, type: 'json', text: tweet.text.gsub(/http(s|):[\/\w\-\_\.\!\*\'\)\(]+/, "")})
      #レスポンスをパースする
      result = JSON.parse(response.body)
      translated_text = result['resultset']['result']['text']
      #ツイートする
      unless translated_text.empty?
        set_twitter_api.update("#{translated_text}")
      end
    end
    # render plain: result['resultset']['result']['text'].empty?
    # @check = result['resultset']['result']['text'].methods
  end
  

  def check_methods
    @check = set_twitter_api.status(1262363944338944000)
  end

  private

  def set_twitter_api
    return rest_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = Rails.application.credentials[:twitter][:API_key]
      config.consumer_secret     = Rails.application.credentials[:twitter][:API_secret]
      config.access_token        = Rails.application.credentials[:twitter][:access_token]
      config.access_token_secret = Rails.application.credentials[:twitter][:access_token_secret]
    end
  end
  
  def set_translate_api
    consumer = OAuth::Consumer.new(Rails.application.credentials[:nict][:translate_key], Rails.application.credentials[:nict][:translate_secret])
    return endpoint = OAuth::AccessToken.new(consumer)
  end

end
