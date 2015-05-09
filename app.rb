require "sinatra"
require "sinatra/activerecord"
require "sinatra/json"
require "json"
require "will_paginate"
require "will_paginate/active_record"
require "qiniu"
require "carrierwave"
require "carrierwave/orm/activerecord"
require "carrierwave-qiniu"
require "rack-flash"
require "i18n"
require "i18n/backend/fallbacks"
require "sanitize"
require "./environments"

enable :sessions

set :session_secret, ENV['SESSION_KEY']

use Rack::Flash

helpers do

  def post_list(post)
    erb :"forum/_post_list", locals: { post: post}
  end

  def new_edit_js
    erb :"forum/topic/_new_edit_js"
  end

  def delete_some(route)
    erb :"forum/_delete_some", locals: { route: route }
  end

  def new_edit_form(post)
    erb :"forum/topic/_form", locals: { post: post }
  end

  def login? 
    !session[:user_id].nil?
  end

  def is_login
    unless login? 
      flash[:notice] = t(:login_notice) 
      redirect '/login'
    end
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

  def real_name(user)
    if user.fake 
      user.fake
    else
      user.name
    end
  end

  def t(text)
    I18n.t(text)
  end

  def h(text)
    Rack::Utils.escape_html(text)
  end

  def sanitize_restricted(html)
    Sanitize.fragment(html,Sanitize::Config::RESTRICTED)
  end

  def sanitize_relaxed(html)
    Sanitize.fragment(html,Sanitize::Config::RELAXED)
  end

end

class AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick


  storage :qiniu
  self.qiniu_protocal = "http"
  self.qiniu_can_overwrite = true

  process :resize_to_fit => [100,100]

  def store_dir
    "avatar"
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def filename
    "avatar#{model.id}" if original_filename.present?
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

  VALID_NAME = /\A\w+\z/
  validates :name, presence: true, format: { with: VALID_NAME }, length: { maximum: 25 }, uniqueness: { case_sensitive: false }
  VALID_EMAIL = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL },uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, on: :create
  validates :password_confirmation, presence: true, on: :create

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
  has_many :notifications, dependent: :destroy

  belongs_to :post
  belongs_to :user
end

class Notification < ActiveRecord::Base
  validates :user_id, presence: true
  validates :comment_id, presence: true
  belongs_to :user
  belongs_to :comment
end



## post routes
#

get "/" do
  @top_posts = Post.where(top: true).order("last_reply_time DESC")
  @posts = Post.where(top: false).paginate(page: params[:page], per_page: 10).order("last_reply_time DESC")
  erb :"forum/index"
end

get "/topics/new" do
  is_login
  @post = Post.new
  erb :"forum/topic/new"
end

post "/topics" do
  is_login
  user = User.find(session[:user_id])
  @post = user.posts.build(params[:post])
  @post.title = sanitize_restricted(@post.title)
  @post.tag = sanitize_restricted(@post.tag)
  @post.body = sanitize_relaxed(@post.body)
  if @post.save
    @post.last_reply_time = @post.created_at
    if @post.tag == "置顶" && user.admin?
      @post.top = true
    else
      @post.tag = "闲聊"
    end
    @post.save    
    flash[:success] = t(:post_success) 
    redirect "/topics/#{@post.id}"
  else
    flash.now[:error] = t(:post_error)
    erb :"forum/topic/new"
  end
end


get "/topics/:id" do
  if (@post = Post.find_by_id(params[:id]))
    @comments = @post.comments.paginate(page: params[:page], per_page: 10)
    atwho =  @comments.map do |comment|
      comment.user
    end
    atlist = atwho.uniq.map do |user|
      {name: real_name(user), url: "/account/#{user.name}"}
    end
    @items = atlist.to_json
    erb :"forum/topic/show"
  else
    erb :"pages/404"
  end
end

get "/topics/:id/edit" do
  is_login
  @post = User.find(session[:user_id]).posts.find(params[:id])
  erb :"forum/topic/edit"
end

patch "/topics/:id" do
  is_login
  @post = User.find(session[:user_id]).posts.find(params[:id])
  if @post.update_attributes(params[:post].delete_if {|key, value| key == "user_id"})
    @post.title = sanitize_restricted(@post.title)
    @post.tag = sanitize_restricted(@post.tag)
    @post.body = sanitize_relaxed(@post.body)
    @post.save
    flash[:success] = t(:post_modify_success) 
    redirect "/topics/#{@post.id}"
  else
    flash[:error] = t(:post_modify_error)
    erb :"forum/topic/edit"
  end
end


delete "/topics/:id" do
  is_login
  if admin?
    @post = Post.find(params[:id]).destroy
    redirect "/"
  else
    flash[:notice] = t(:permission_notice)
    redirect "/"
  end
end

get "/topics/:id/essence" do
  is_login
  if admin?
    post = Post.find(params[:id])
    post.essence = true
    post.save
    redirect "/topics/#{params[:id]}"
  else
    flash[:notice] = t(:permission_notice)
    redirect "/"
  end
end

get "/tags/:tag" do
  @posts = Post.where("tag = ?", params[:tag]).order("last_reply_time DESC")
  erb :"forum/tags"
end

# user routes


get "/signup" do
  @user = User.new
  erb :"forum/user/new"
end

post "/signup" do
  @user = User.new(params[:user].delete_if { |key,value| key == "admin" })
  @user.name = sanitize_restricted(@user.name)
  if @user.save
    session[:user_id] = @user.id
    flash[:success] = t(:user_success)
    redirect '/'
  else
    flash.now[:error] = t(:user_error)
    erb :"forum/user/new"
  end

end

get "/login" do
  @user = User.new
  erb :"forum/user/login"
end 

get "/logout" do
  is_login
  session.clear
  flash[:success] = t(:user_logout)
  redirect '/'
end

post "/login" do
  @user = User.find_by_email(params[:session][:email])
  if @user && @user.authenticate(params[:session][:password])
    session[:user_id] = @user.id
    flash[:success] = t(:user_login_success)
    redirect "/"
  else
    flash.now[:notice] = t(:user_login_error)
    erb :"forum/user/login"
  end
end

get "/account/:name" do
  is_login
  if (@user = User.find_by_name(params[:name]))
    @posts = @user.posts.paginate(page: params[:page], per_page: 5)
    @comments = @user.comments.paginate(page: params[:page], per_page: 5)
    erb :"forum/user/show"
  else
    erb :"pages/404", layout: false 
  end
end

get "/account/:name/edit" do
  is_login
  if (User.find(session[:user_id]) == User.find_by_name(params[:name]))
  @user = User.find(session[:user_id])
  erb :"forum/user/edit"
  else
    flash[:notice] = t(:permission_notice)
    redirect "/"
  end
end

patch "/users" do
  is_login
  @user = User.find(session[:user_id])
  if @user.update_attributes(params[:user].delete_if{ |key,value| key == "email"or key == "name" or key == "admin"}) 
    @user.fake = sanitize_restricted(@user.fake)
    @user.city = sanitize_restricted(@user.city)
    @user.info = sanitize_restricted(@user.info)
    @user.save
    redirect "/account/#{@user.name}"
  else
    erb :"forum/user/edit" 
  end
end

delete "/users/:id" do
  is_login
  if admin?
    User.find(params[:id]).destroy
    redirect "/"
  else
    flash[:notice] = t(:permission_notice)
    redirect "/"
  end
end

#comment routes
  
post "/comments/:id" do # need to change
  is_login
  comment = User.find(session[:user_id]).comments.build(params[:comment])
  comment.post_id = params[:id]
  comment.body = sanitize_relaxed(comment.body)
  if comment.save
      post = Post.find(params[:id])
      post.last_reply_time = comment.created_at
      post.save
    if ( comment.user != Post.find(params[:id]).user )
      Notification.create(user_id: Post.find(params[:id]).user.id , comment_id: comment.id , user_name: real_name(comment.user) , post_name: Post.find(params[:id]).title )
    end
    flash[:success] = t(:comment_success)
    redirect "/topics/#{params[:id]}"
  else
    flash[:error] = t(:comment_error)
    redirect "/topics/#{params[:id]}"
  end
end

post "/comments/:id/:name" do
  is_login
  comment = User.find(session[:user_id]).comments.build(params[:comment])
  comment.post_id = params[:id]
  comment.body = sanitize_relaxed(comment.body)
  if comment.save
    post = Post.find(params[:id])
    post.last_reply_time = comment.created_at
    post.save

    Notification.create(user_id: User.find_by_name(params[:name]).id, comment_id: comment.id , user_name: real_name(comment.user), post_name: Post.find(params[:id]).title, atwho: true)

    flash[:success] = t(:comment_success)
    redirect "/topics/#{params[:id]}"
  else
    flash[:error] = t(:comment_error)
    redirect "/topics/#{params[:id]}"
  end
end


delete "/comments/:id" do
  is_login
  if admin?
    post = Comment.find(params[:id]).post
    Comment.find(params[:id]).destroy
    redirect "/topics/#{post.id}"
  else
    flash[:notice] = t(:permission_notice)
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
    flash[:notice] = t(:permission_notice)
    redirect "/"
  end
end

delete "/notifications/:id" do
  is_login
  if (User.find(session[:user_id]) == User.find(Notification.find(params[:id]).user_id))
    Notification.find(params[:id]).destroy
    redirect "/account/#{User.find(session[:user_id]).name}"
  else
    flash[:notice] = t(:permission_notice)
    redirect "/"
  end
end

# page routes

get "/about" do
  erb :"pages/about"
end

not_found do
  erb :"pages/404", layout: false
end
