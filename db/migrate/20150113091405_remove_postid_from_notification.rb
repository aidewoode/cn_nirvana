class RemovePostidFromNotification < ActiveRecord::Migration
  def change
    remove_column :notifications, :post_id
    add_column :notifications, :post_name, :string
    rename_column :notifications, :name, :user_name
  end
end
