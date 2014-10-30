class AddTopToPost < ActiveRecord::Migration
  def change
    add_column :posts, :top, :boolean, default: false
  end
end
