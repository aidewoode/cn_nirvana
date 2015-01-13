class AddAtwhoToNotification < ActiveRecord::Migration
  def change
      add_column :notifications, :atwho, :boolean, default: false
  end
end
