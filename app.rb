require "sinatra"
require "sinatra/activerecord"
require "will_paginate"
require "will_paginate/active_record"
require "qiniu"
require "carrierwave"
require "carrierwave/orm/activerecord"
require "carrierwave-qiniu"
#require "mini_magick"
require "rack-flash"
require "i18n"
require "i18n/backend/fallbacks"
require "sanitize"
require "./environments"

enable :sessions

set :session_secret, "super secret"

use Rack::Flash

helpers do

  def pretty_time(time)
    time.strftime("%Y/%m/%d")
  end

  def post_list(post)
    erb :"form/_post_list", locals: { post: post}
  end

  def new_edit_js
    erb :"form/topic/_new_edit_js"
  end

  def delete_some(route)
    erb :"form/_delete_some", locals: { route: route }
  end

  def new_edit_form(post)
    erb :"form/topic/_form", locals: { post: post }
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

  validates :name, presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: false }
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
  @post.title = sanitize_restricted(@post.title)
  @post.tag = sanitize_restricted(@post.tag)
  @post.body = sanitize_relaxed(@post.body)
  if @post.save
    @post.last_reply_time = @post.created_at
    if @post.tag == "置顶"
      @post.top = true
    end
    @post.save    
    flash[:success] = t(:post_success) 
    redirect "/topics/#{@post.id}"
  else
    flash.now[:error] = t(:post_error)
    erb :"form/topic/new"
  end
end


get "/topics/:id" do
  if (@post = Post.find_by_id(params[:id]))
    @comments = @post.comments.paginate(page: params[:page], per_page: 10)
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
    erb :"form/topic/edit"
  end
end


delete "/topics/:id" do
  is_login
  if User.find(session[:user_id]).admin?
    @post = Post.find(params[:id]).destroy
    redirect "/"
  else
    flash[:notice] = t(:permission_notice)
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
  @user.name = sanitize_restricted(@user.name)
  if @user.save
    session[:user_id] = @user.id
    flash[:success] = t(:user_success)
    redirect '/'
  else
    flash.now[:error] = t(:user_error)
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
    erb :"form/user/login"
  end
end

get "/account/:name" do
  is_login
  if (@user = User.find_by_name(params[:name]))
    @posts = @user.posts.paginate(page: params[:page], per_page: 5)
    @comments = @user.comments.paginate(page: params[:page], per_page: 5)
    erb :"form/user/show"
  else
    erb :"pages/404", layout: false 
  end
end

get "/account/:name/edit" do
  is_login
  if (User.find(session[:user_id]) == User.find_by_name(params[:name]))
  @user = User.find(session[:user_id])
  erb :"form/user/edit"
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
    erb :"form/user/edit" 
  end
end

delete "/users/:id" do
  is_login
  if User.find(session[:user_id]).admin?
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
      Notification.create(user_id: Post.find(params[:id]).user.id, comment_id: comment.id )
    end
    flash[:success] = t(:comment_success)
    redirect "/topics/#{params[:id]}"
  else
    flash[:error] = t(:comment_error)
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
