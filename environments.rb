configure do
  Qiniu.establish_connection! :access_key => "L1fAWQtmukT5ioWrF8FicxiWpcA85LW6kpo8O-hy",
                              :secret_key => "vT8rNzRdIciO78Bqtleu6TvRwzXOR0aldpGD7Hc6"
end

configure :development do
  set :database , "sqlite3:blog.db"
end

configure :production do
  db = URI.parse(ENV['DATABASE_URL'])

  ActiveRecord::Base.establish_connection(
    :adapter => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
    :host => db.host,
    :username => db.user,
    :password => db.password,
    :database => db.path[1..-1],
    :encoding => 'utf8'
  )
end
