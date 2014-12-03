class RemoveLastReplyFormPosts < ActiveRecord::Migration
  def change
    remove_column :posts, :last_reply
  end
end
