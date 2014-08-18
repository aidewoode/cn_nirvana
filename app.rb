
require "sinatra"
require "sinatra/activerecord"

set :database, "sqlite3:blog.db"

helpers do


  def pretty_date(time)
    time.strftime("%d %b %Y")
  end

  def post_show_pages?
    request.path_info =~ /\/posts\/\d+$/
  end

  def delete_post_button(post_id)
    erb :_delete_post_button, locals: { post_id: post_id}
  end
end

class Post < ActiveRecord::Base
  validates :title, presence: true, length: { minimum: 3}
  validates :body, presence: true
  validates :tag, presence: true

end 

class User < ActiveRecord::Base
  has_secure_password
end


get "/" do
  @posts = Post.order("created_at DESC") # 需要改进。
  erb :"posts/index"
end

get "/posts/new" do
  @post = Post.new
  erb :"posts/new"
end

post "/posts" do
  @post = Post.new(params[:post])
  if @post.save
    redirect "/posts/#{@post.id}"
  else
    erb :"posts/new"
  end
end

get "/posts/:id" do
  @post = Post.find(params[:id])
  erb :"posts/show"
end

get "/posts/:id/edit" do
  @post = Post.find(params[:id])
  erb :"posts/edit"
end

put "/posts/:id" do
  @post = Post.find(params[:id])
  if @post.update_attributes(params[:post])
    redirect "/posts/#{@post.id}"
  else
    erb :"posts/edit"
  end
end
# Test why erb :"posts/edit"


delete "/posts/:id" do
  @post = Post.find(params[:id]).destroy
  redirect "/"
end

get "/tags/:tag" do
  @posts = Post.where("tag = ?", params[:tag]).order(created_at: :desc)
  erb :"posts/tags"
  # 添加渲染模版。
end

get "/about" do
  erb :"pages/about"
end

