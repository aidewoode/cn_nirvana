require "sinatra"
require "sinatra/activerecord"
require "redcarpet"
require "qiniu"
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

  def delete_post(post_id)
    erb :"form/topic/_delete_post", locals: { post_id: post_id}
  end

  def post_each(posts)
    erb :"form/_post_each", locals: { posts: posts}
  end

  def new_edit_form(post)
    erb :"form/topic/_form", locals: { post: post }
  end

  def login? 
    !session[:user_id].nil?
  end

  def delete_user(user_id)
    erb :"form/user/_delete_user", locals: { user_id: user_id }
  end

  def delete_comment(comment_id)
    erb :"form/topic/_delete_comment", locals: { comment_id: comment_id}
  end

  def delete_notification(notification_id)
    erb :"form/user/_delete_notification", locals: { notification_id: notification_id}
  end

  def mark_down(post)
   markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, quote: true) 
   markdown.render(post)
  end

  def admin?
    User.find(session[:user_id]).admin?
  end

  def current_user?(user_id)
    User.find(user_id) == User.find(session[:user_id])
  end

  def current_user 
    @user = User.find(session[:user_id])
  end

  def time_ago(start_time)
    diff = Time.now - start_time
    case diff
    when 0..59
       "一分钟前"
    when 60..(3600-1)
       "#{(diff/60).to_i} 分钟前"
    when 3600..(3600*24-1)
       "#{(diff/3600).to_i} 小时前"
    when (3600*24)..(3600*24*30)
       "#{(diff/(3600*24).to_i)} 天前"
    else
       start_time.strftime( "%Y/%m/%d")
    end
  end

end

class Post < ActiveRecord::Base
  validates :title, presence: true, length: { minimum: 3}
  validates :body, presence: true
  validates :tag, presence: true
  validates :user_id , presence: true

  has_many :comments, dependent: :destroy
  belongs_to :user

end 

class User < ActiveRecord::Base

  before_save { |user| user.email = email.downcase ; user.name = name.downcase }

  validates :name, presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: false }
  VALID_EMAIL = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL },uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, on: create
  validates :password_confirmation, presence: true, on: create
  
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :notifications, dependent: :destroy

  has_secure_password
end

class Comment < ActiveRecord::Base
  validates :body, presence: true
  validates :user_id, presence: true
  validates :post_id, presence: true

  belongs_to :post
  belongs_to :user
end

class Notification < ActiveRecord::Base
  validates :user_id, presence: true
  validates :comment_id, presence: true
  belongs_to :user
end




## post routes

def is_login
  redirect '/login' unless login?
end

get "/" do
  @posts = Post.order("created_at DESC") # 需要改进。
  erb :"form/index"
end

get "/topics" do
  @posts = Post.order("created_at DESC") 
  @comments = Comment.all
  erb :"form/topics"
end

get "/topics/new" do
  is_login
  @post = Post.new
  erb :"form/topic/new"
end

post "/topics" do
  is_login
  user = User.find(session[:user_id])
  @post = user.posts.build(params[:post])
  if @post.save
    redirect "/topics/#{@post.id}"
  else
    erb :"form/topic/new"
  end
end

get "/topics/:id" do
  if (@post = Post.find_by_id(params[:id]))
    @comments = @post.comments
    erb :"form/topic/show"
  else
    erb :"pages/404"
  end
end

get "/topics/:id/edit" do
  is_login
  @post = User.find(session[:user_id]).posts.find(params[:id])
  erb :"form/topic/edit"
end

put "/topics/:id" do
  is_login
  post = User.find(session[:user_id]).posts.find(params[:id])
  if post.update_attributes(params[:post].delete_if {|key, value| key == "user_id"})
    redirect "/topics/#{post.id}"
  else
    erb :"form/topic/edit"
  end
end


delete "/topics/:id" do
  is_login
  if User.find(session[:user_id]).admin?
    @post = Post.find(params[:id]).destroy
  else
    redirect "/"
  end
end

get "/tags/:tag" do
  @posts = Post.where("tag = ?", params[:tag]).order(created_at: :desc)
  erb :"form/tags"
end

# user routes


get "/signup" do
  erb :"form/user/new"
end

post "/users" do
  user = User.new(params[:user].delete_if { |key,value| key == "admin" })
  if user.save
    redirect '/'
  else
    redirect 'form/user/new'
  end

end

get "/login" do
  erb :"pages/login", :layout => false
end 

get "/logout" do
  is_login
  session.clear
  redirect '/'
end

post "/sessions" do
  @user = User.find_by_email(params[:session][:email])
  if @user && @user.authenticate(params[:session][:password])
    session[:user_id] = @user.id
    redirect "/account/#{@user.name}"
  else
    redirect '/login'
  end
end

get "/account/:name" do
  is_login
  if (@user = User.find_by_name(params[:name]))
    @comments = Comment.all
    erb :"form/user/show"
  else
    erb :"pages/404"
  end
end

get "/account/:name/edit" do
  is_login
  if (User.find(session[:user_id]) == User.find_by_name(params[:name]))
  @user = User.find(session[:user_id])
  put_policy = Qiniu::Auth::PutPolicy.new("cnnirvana")
  @uptoken = Qiniu::Auth.generate_uptoken(put_policy)
  erb :"form/user/edit"
  else
    erb :"pages/404"
  end
end

patch "/users" do
  is_login
  @user = User.find(session[:user_id])
  if @user.update_attributes(params[:user].delete_if{ |key,value| key == "admin"})
    redirect "/account/#{@user.name}"
  else
    erb :"form/user/edit" # like render
  end
end

delete "/users/:id" do
  is_login
  if User.find(session[:user_id]).admin?
    User.find(params[:id]).destroy
  else
    erb :"pages/404"
  end
end

#comment routes
  
post "/comments/:id" do
  is_login
  comment = User.find(session[:user_id]).comments.build(params[:comment])
  comment.post_id = params[:id]
  if comment.save
    Notification.create(user_id: Post.find(params[:id]).user.id, comment_id: comment.id )
    post = Post.find(params[:id])
    post.last_reply = comment.id
    post.save
    redirect "/topics/#{params[:id]}"
  else
    redirect "/"
  end
end

delete "/comments/:id" do
  is_login
  if User.find(session[:user_id]).admin?
    post = Comment.find(params[:id]).post
    Comment.find(params[:id]).destroy
    redirect "/topics/#{post.id}"
  else
    erb :"pages/404"
  end
end

# notification routes

get "/notifications/:id" do
  is_login
  if (User.find(session[:user_id]) == User.find(Notification.find(params[:id]).user_id))
    noti = Notification.find(params[:id])
    noti.read = true
    noti.save
    redirect "/topics/#{Comment.find(noti.comment_id).post.id}"
  else
    erb :"pages/404"
  end
end

delete "/notifications/:id" do
  is_login
  if (User.find(session[:user_id]) == User.find(Notification.find(params[:id]).user_id))
    Notification.find(params[:id]).destroy
    redirect "/account/#{User.find(session[:user_id]).name}"
  else
    erb :"pages/404"
  end
end

# page routes

get "/about" do
  erb :"pages/about"
end

not_found do
  erb :"pages/404", :layout => false
end
