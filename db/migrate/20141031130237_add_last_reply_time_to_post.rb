class AddLastReplyTimeToPost < ActiveRecord::Migration
  def change
    add_column :posts, :last_reply_time, :datetime
  end
end
