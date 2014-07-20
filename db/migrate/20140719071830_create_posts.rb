class CreatePosts < ActiveRecord::Migration
  def up
    create_table :posts do |t|
      t.string :title
      t.text :body
      t.timestamps
    end
    Post.create(title: "My first blog", body: "This is my first blog.")
    Post.create(title: "我的第一篇博客", body: "这是我的第一篇博客。")

  end

  def down
    drop_table :posts
  end

end
