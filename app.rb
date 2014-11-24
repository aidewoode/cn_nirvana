require "sinatra"
require "sinatra/activerecord"
require "will_paginate"
require "will_paginate/active_record"
require "qiniu"
require "carrierwave"
require "carrierwave/orm/activerecord"
require "carrierwave-qiniu"
require "rack-flash"
require "./environments"

enable :sessions

set :session_secret, "super secret"

use Rack::Flash

helpers do


  def pretty_time(time)
    time.strftime("%Y/%m/%d")
  end

  def delete_post(post_id)
    erb :"form/topic/_delete_post", locals: { post_id: post_id}
  end

  def new_edit_form(post)
    erb :"form/topic/_form", locals: { post: post }
  end

  def login? 
    !session[:user_id].nil?
  end

  def is_login
    unless login? 
      flash[:notice] = "请先登录"
      redirect '/login'
    end
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
       "刚刚不久"
    when 60..(3600-1)
       "#{(diff/60).to_i} 分钟前"
    when 3600..(3600*24-1)
       "#{(diff/3600).to_i} 小时前"
    when (3600*24)..(3600*24*30)
       "#{((diff/(3600*24)).to_i)} 天前"
    else
       start_time.strftime( "%Y/%m/%d")
    end
  end

end

class AvatarUploader < CarrierWave::Uploader::Base
  storage :qiniu
  self.qiniu_protocal = "http"
  self.qiniu_can_overwrite = true

  def store_dir
    "avatar"
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def filename
    "avatar#{model.id}.#{file.extension}" if original_filename.present?
  end

  def default_url
    "http://cnnirvana.qiniudn.com/avatar/default.png"
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

  mount_uploader :avatar, AvatarUploader
  
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


get "/" do
  @top_posts = Post.where(top: true).order("last_reply_time DESC")
  @posts = Post.where(top: false).paginate(page: params[:page], per_page: 5).order("last_reply_time DESC")
  erb :"form/index"
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
    @post.last_reply_time = @post.created_at
    @post.save    
    flash[:success] = "发表成功"
    redirect "/topics/#{@post.id}"
  else
    flash.now[:error] = "出现错误"
    erb :"form/topic/new"
  end
end


get "/topics/:id" do
  if (@post = Post.find_by_id(params[:id]))
    @comments = @post.comments.paginate(page: params[:page], per_page: 5)
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
  @post = User.find(session[:user_id]).posts.find(params[:id])
  if @post.update_attributes(params[:post].delete_if {|key, value| key == "user_id"})
    flash[:success] = "修改成功"
    redirect "/topics/#{@post.id}"
  else
    flash[:error] = "修改失败"
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
  @posts = Post.where("tag = ?", params[:tag]).order(last_reply_time: :desc)
  @comments = Comment.all
  erb :"form/tags"
end

# user routes


get "/signup" do
  @user = User.new
  erb :"form/user/new"
end

post "/signup" do
  @user = User.new(params[:user].delete_if { |key,value| key == "admin" })
  if @user.save
    flash[:success] = "注册成功"
    redirect '/'
  else
    flash.now[:error] = "注册失败"
    erb :"form/user/new"
  end

end

get "/login" do
  @user = User.new
  erb :"form/user/login"
end 

get "/logout" do
  is_login
  session.clear
  flash[:success] = "登出成功"
  redirect '/'
end

post "/login" do
  @user = User.find_by_email(params[:session][:email])
  if @user && @user.authenticate(params[:session][:password])
    session[:user_id] = @user.id
    flash[:success] = "登录成功"
    redirect "/"
  else
    flash.now[:notice] = "登录失败,密码或Email 错误"
    erb :"form/user/login"
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
  erb :"form/user/edit"
  else
    flash[:notice] = "禁止访问，你的权限不够"
    redirect "/"
  end
end

patch "/users" do
  is_login
  @user = User.find(session[:user_id])
  if @user.update_attributes(params[:user].delete_if{ |key,value| key == "email"or key == "name" or key == "admin"}) 
    redirect "/account/#{@user.name}"
  else
    erb :"form/user/edit" 
  end
end

delete "/users/:id" do
  is_login
  if User.find(session[:user_id]).admin?
    User.find(params[:id]).destroy
  else
    flash[:notice] = "禁止访问，你的权限不够"
    redirect "/"
  end
end

#comment routes
  
post "/comments/:id" do # need to change
  is_login
  comment = User.find(session[:user_id]).comments.build(params[:comment])
  comment.post_id = params[:id]
  if comment.save
      post = Post.find(params[:id])
      post.last_reply = comment.id
      post.last_reply_time = comment.created_at
      post.save
    if ( comment.user != Post.find(params[:id]).user )
      Notification.create(user_id: Post.find(params[:id]).user.id, comment_id: comment.id )
    end
    flash[:success] = "回复成功"
    redirect "/topics/#{params[:id]}"
  else
    flash[:error] = "回复失败,回复不能为空"
    redirect "/topics/#{params[:id]}"
  end
end

delete "/comments/:id" do
  is_login
  if User.find(session[:user_id]).admin?
    post = Comment.find(params[:id]).post
    Comment.find(params[:id]).destroy
    redirect "/topics/#{post.id}"
  else
    flash[:notice] = "禁止访问，你的权限不够"
    redirect "/"
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
    flash[:notice] = "禁止访问，你的权限不够"
    redirect "/"
  end
end

delete "/notifications/:id" do
  is_login
  if (User.find(session[:user_id]) == User.find(Notification.find(params[:id]).user_id))
    Notification.find(params[:id]).destroy
    redirect "/account/#{User.find(session[:user_id]).name}"
  else
    flash[:notice] = "禁止访问，你的权限不够"
    redirect "/"
  end
end

# page routes

get "/about" do
  erb :"pages/about"
end

not_found do
  erb :"pages/404", :layout => false
end
