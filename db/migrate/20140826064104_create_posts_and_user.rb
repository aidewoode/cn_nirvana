class CreatePostsAndUser < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :title
      t.text :body
      t.string :tag
      t.timestamps
    end

    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :password_digest
    end
  end
end
