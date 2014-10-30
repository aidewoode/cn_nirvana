class AddLastReplyToPost < ActiveRecord::Migration
  def change
    add_column :posts, :last_reply, :integer
  end
end
