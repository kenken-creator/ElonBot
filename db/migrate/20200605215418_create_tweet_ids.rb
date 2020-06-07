class CreateTweetIds < ActiveRecord::Migration[6.0]
  def change
    create_table :tweet_ids do |t|
      t.text :status_id
      t.timestamps
    end
  end
end
