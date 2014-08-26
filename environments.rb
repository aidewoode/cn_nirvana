configure :development do
  set :database , "sqlite3:blog.db"
end

configure :production do
  db = URI.parse("postgres://ntowdmawnahglf:kP6ymEOZUBRce5Anbuzp5o5ELC@ec2-54-204-24-154.compute-1.amazonaws.com:5432/ddbjfgc23a5kqi")
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
