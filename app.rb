
require "sinatra"
require "sinatra/activerecord"
require "redcarpet"
require "./environments"

enable :sessions

set :session_secret, "super secret"

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

  def post_each(posts)
    erb :"posts/_post_each", locals: { posts: posts}
  end

  def new_edit_form(post)
    erb :"posts/_form", locals: { post: post }
  end

  def login? 
    !session[:user_id].nil?
  end

  def is_login
    redirect '/login' unless login?
  end

  def mark_down(post)
   markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, quote: true) 
   markdown.render(post)
  end

end

class Post < ActiveRecord::Base
  validates :title, presence: true, length: { minimum: 3}
  validates :body, presence: true
  validates :tag, presence: true
  belongs_to :user

end 

class User < ActiveRecord::Base
  validates :name, presence: true
  validates :email, presence: true
  validates :password, presence: true
  has_many :posts

  has_secure_password
end

class Comment < ActiveRecord::Base
  validates :body, presence: true
  belongs_to :post
  belongs_to :user
end

## post routes
#
get "/" do
  @posts = Post.order("created_at DESC") # 需要改进。
  erb :"posts/index"
end

get "/posts/new" do
  is_login
  @post = Post.new
  erb :"posts/new"
end

post "/posts" do
  is_login
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
  is_login
  @post = Post.find(params[:id])
  erb :"posts/edit"
end

put "/posts/:id" do
  is_login
  @post = Post.find(params[:id])
  if @post.update_attributes(params[:post])
    redirect "/posts/#{@post.id}"
  else
    erb :"posts/edit"
  end
end


delete "/posts/:id" do
  is_login
  @post = Post.find(params[:id]).destroy
  redirect "/"
end

get "/tags/:tag" do
  @posts = Post.where("tag = ?", params[:tag]).order(created_at: :desc)
  erb :"posts/tags"
end

# user routes

get "/login" do
  erb :"pages/login", :layout => false
end 

get "/logout" do
  is_login
  session.clear
  redirect '/'
end

post "/sessions" do
  user = User.find_by_email(params[:session][:email])
  if user && user.authenticate(params[:session][:password])
    session[:user_id] = user.id
    redirect '/'
  else
    redirect '/login'
  end
end

# page routes
#
get "/about" do
  erb :"pages/about"
end

not_found do
  erb :"pages/404", :layout => false
end
