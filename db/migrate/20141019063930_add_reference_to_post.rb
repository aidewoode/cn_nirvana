class AddReferenceToPost < ActiveRecord::Migration
  def change
    add_references :posts, :user, index: true
  end
end
