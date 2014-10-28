class AddEssenceToPost < ActiveRecord::Migration
  def change
    add_column :posts, :essence, :boolean, default: false
  end
end
