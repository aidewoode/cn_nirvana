class AddIndexToTag < ActiveRecord::Migration
  def change
    add_index :posts, :tag

  end
end
