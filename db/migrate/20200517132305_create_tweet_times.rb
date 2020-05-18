class CreateTweetTimes < ActiveRecord::Migration[6.0]
  def change
    create_table :tweet_times do |t|
      t.datetime :tweet_created_at
      t.timestamps
    end
  end
end
