class AddNameToNotification < ActiveRecord::Migration
  def change
    add_column :notifications, :name, :string
  end
end
