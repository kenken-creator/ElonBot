namespace :translate_and_tweet do
  desc "tweetを翻訳してそのtweetのurlと共に訳文をツイートする"
  task tweet: :environment do
    puts "tweetします"
  end
end
