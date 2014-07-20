
require "sinatra"
require "sinatra/activerecord"

set :database, "sqlite3:blog.db"

helpers do

  def title
    if @title
      "#{@title} -- Aide's Blog"
    else
      "Aide's Blog"
    end
  end

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

end 

class User < ActiveRecord::Base
end

get "/" do
  @posts = Post.order("created_at DESC")
  erb :"posts/index"
end

get "/posts/new" do
  @title = "New Post"
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
  @title = @post.title
  erb :"posts/show"
end

get "/posts/:id/edit" do
  @post = Post.find(params[:id])
  @title = "Edit Form"
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

get "/about" do
  @title = "About Me"
  erb :"pages/about"
end
