class AddCommentIndexToNotification < ActiveRecord::Migration
  def change
    add_index :notifications, :comment_id
  end
end
