namespace :translate_and_tweet do
  desc "特定のアカウントのtweetを翻訳してそのtweetのurlと共に訳文をツイートする"
  task user: :environment do
    logger = Logger.new 'log/translate_and_tweet.log'
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

    rest_client = set_twitter_api
    @user_timeline = rest_client.user_timeline("SpaceX").take(10).reverse
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
              rest_client.update("RT by @#{tweet.user.screen_name}\n#トランプ #{tweet.retweeted_status.url}")
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
    
  end


  desc "blacklivesmatterを含むtweetを翻訳してそのtweetのurlと共に訳文をツイートする"
  task blacklivesmatter: :environment do
    logger = Logger.new 'log/translate_and_tweet.log'
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

    rest_client = set_twitter_api
    tweets = rest_client.search("blacklivesmatter", result_type: :popular, max_id: TweetId.last.status_id.to_i - 1, lang: :en).take(5).reverse

    endpoint = set_translate_api
    url = "https://mt-auto-minhon-mlt.ucri.jgn-x.jp/api/mt/generalNT_en_ja/"
    translate_key = Rails.application.credentials[:nict][:translate_key]
    name = 'kenkenchi'

    ids = []
    tweets.each do |tweet|
      ids << tweet.id
      text_without_url = tweet.text.gsub(/#blacklivesmatter|#BlackLivesMatter|http(s|):[\/\w\-\_\.\!\*\'\)\(]+/, '')
      retweet_text_without_url = tweet.retweeted_status.text.gsub(/#blacklivesmatter|#BlackLivesMatter|http(s|):[\/\w\-\_\.\!\*\'\)\(]+/, '') if tweet.retweet?
      unless tweet.reply?
        
        if tweet.retweet?
          if retweet_text_without_url.empty?
            rest_client.update("RT by @#{tweet.user.screen_name}\n#BlackLivesMatter #人種差別 #{tweet.retweeted_status.url}")
          else
            response = endpoint.post(url,{key: translate_key, name: name, type: 'json', text: retweet_text_without_url})
            result = JSON.parse(response.body)
            translated_retweet_text = result['resultset']['result']['text']
            rest_client.update("#{translated_retweet_text}\nRT by @#{tweet.user.screen_name}\n#BlackLivesMatter #人種差別 #{tweet.retweeted_status.url}")
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
                rest_client.update("#{translated_text}\n#BlackLivesMatter #人種差別 #{tweet.url}")
              else
                rest_client.update("#{translated_text}\n引用RT by @#{tweet.user.screen_name}\n#BlackLivesMatter #人種差別 #{tweet.quoted_status.url}")
              end
              
            else
                rest_client.update("#{translated_text}\n#BlackLivesMatter #人種差別 #{tweet.url}")
            end
          end
        end   
      end
    end

    TweetId.create(status_id: ids.sort.first)
  
    
  end
end
