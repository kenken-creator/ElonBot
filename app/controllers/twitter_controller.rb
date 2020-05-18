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
    @user_timeline = rest_client.user_timeline("ladygaga").take(20).reverse
    last_data_time = TweetTime.last.tweet_created_at
    last_tweet_time = @user_timeline.last.created_at

    endpoint = set_translate_api
    url = "https://mt-auto-minhon-mlt.ucri.jgn-x.jp/api/mt/generalNT_en_ja/"
    translate_key = Rails.application.credentials[:nict][:translate_key]
    name = 'kenkenchi'

    index = 0
    @user_timeline.each do |tweet|
      text_without_url = tweet.text.gsub(/http(s|):[\/\w\-\_\.\!\*\'\)\(]+/, "")
      retweet_text_without_url = tweet.retweeted_status.text.gsub(/http(s|):[\/\w\-\_\.\!\*\'\)\(]+/, "") if tweet.retweet?
      if last_data_time < tweet.created_at
        unless tweet.reply?
          
          if tweet.retweet?
            if retweet_text_without_url.empty?
              rest_client.update("RT by @#{tweet.user.screen_name} #{tweet.retweeted_status.url}")
            else
              response = endpoint.post(url,{key: translate_key, name: name, type: 'json', text: retweet_text_without_url})
              result = JSON.parse(response.body)
              translated_retweet_text = result['resultset']['result']['text']
              rest_client.update("#{translated_retweet_text}\nRT by @#{tweet.user.screen_name} #{tweet.retweeted_status.url}")
            end

          else
            if text_without_url.empty?
              rest_client.update("#{tweet.url}")
            else
              response = endpoint.post(url,{key: translate_key, name: name, type: 'json', text: text_without_url})
              result = JSON.parse(response.body)
              translated_text = result['resultset']['result']['text']
              if tweet.quote?
                if tweet.truncated?
                  rest_client.update("#{translated_text} #{tweet.url}")
                else
                  rest_client.update("#{translated_text}\n引用RT by @#{tweet.user.screen_name} #{tweet.quoted_status.url}")
                end
                
              else
                  rest_client.update("#{translated_text} #{tweet.url}")
              end
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
    tweet = set_twitter_api.status(1262407959889338368)
    set_twitter_api.update("#{tweet.text} #{tweet.url}")
    TweetTime.create(tweet_created_at: tweet.created_at)
    render plain: "#{tweet.text}\n#{tweet.url}"
  end

  def check_phenomenon
    tweet = set_twitter_api.user_timeline("Elon04297551").take(2).reverse
    tweet.each do |tweet|
      text_without_url = tweet.text.gsub(/http(s|):[\/\w\-\_\.\!\*\'\)\(]+/, "")
      retweet_text_without_url = tweet.retweeted_status.text.gsub(/http(s|):[\/\w\-\_\.\!\*\'\)\(]+/, "") if tweet.retweet?
      if text_without_url.empty? or retweet_text_without_url.empty?
        if tweet.retweet?
          set_twitter_api.update("RT from #{tweet.user.name} #{tweet.retweeted_status.url}")
        else
          set_twitter_api.update("#{tweet.url}")
        end
        
      end
    end
    render plain: tweet[0].retweeted_status.url
  end

  def translate
    endpoint = set_translate_api
    tweet = set_twitter_api.user_timeline('digitalps').take(10)
    url = "https://mt-auto-minhon-mlt.ucri.jgn-x.jp/api/mt/generalNT_en_ja/"
    translate_key = Rails.application.credentials[:nict][:translate_key]
    name = 'kenkenchi'
    tweet.each do |tweet|
      response = endpoint.post(url,{key: translate_key, name: name, type: 'json', text: tweet.text.gsub(/http(s|):[\/\w\-\_\.\!\*\'\)\(]+/, "")})
      result = JSON.parse(response.body)
      translated_text = result['resultset']['result']['text']
      unless translated_text.empty?
        set_twitter_api.update("#{translated_text}")
      end
    end
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
