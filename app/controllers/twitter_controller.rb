class TwitterController < ApplicationController


  def stream_tweets
    rest_client = set_twitter_api
    @user_timeline = rest_client.search("blacklivesmatter", result_type: :popular, lang: :en).take(10).reverse
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
              rest_client.update("RT by @#{tweet.user.screen_name}\n#blacklivesmatter #{tweet.retweeted_status.url}")
            else
              response = endpoint.post(url,{key: translate_key, name: name, type: 'json', text: retweet_text_without_url})
              result = JSON.parse(response.body)
              translated_retweet_text = result['resultset']['result']['text']
              rest_client.update("#{translated_retweet_text}\nRT by @#{tweet.user.screen_name}\n#blacklivesmatter #{tweet.retweeted_status.url}")
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
                  rest_client.update("#{translated_text}\n#blacklivesmatter #{tweet.url}")
                else
                  rest_client.update("#{translated_text}\n引用RT by @#{tweet.user.screen_name}\n#blacklivesmatter #{tweet.quoted_status.url}")
                end
                
              else
                  rest_client.update("#{translated_text}\n#blacklivesmatter #{tweet.url}")
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

  def update
    set_twitter_api.update("taskのテストーー")
    render plain: 'a'
  end




  def single_tweet
    tweet = set_twitter_api.status(1262407959889338368)
    set_twitter_api.update("#{tweet.text} #{tweet.url}")
    TweetTime.create(tweet_created_at: tweet.created_at)
    render plain: "#{tweet.text}\n#{tweet.url}"
  end

  def check_phenomenon
    @tweets = set_twitter_api.search("blacklivesmatter", result_type: :popular, max_id: TweetId.last.status_id.to_i - 1, lang: :en).take(5).reverse
    @array = []
    @tweets.each do |tweet|
      @array << tweet.id
    end
    @array.sort!
    TweetId.create(status_id: @array.first)
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
    @check = set_twitter_api.status(1264627389599895552).methods
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
