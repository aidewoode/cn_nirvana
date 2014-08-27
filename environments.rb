configure :development do
  set :database , "sqlite3:blog.db"
end

configure :production do
  db = URI.parse(ENV['DATABASE_URL'])
# 需要改进，不要把数据库链接暴露出来。
  ActiveRecord::Base.establish_connection(
    :adapter => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
    :host => db.host,
    :username => db.user,
    :password => db.password,
    :database => db.path[1..-1],
    :encoding => 'utf8'
  )
end
