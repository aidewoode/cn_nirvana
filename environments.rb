CarrierWave.configure do |config|
  config.storage = :qiniu
  config.qiniu_access_key = "S-i191j3raW9PbGfbmxq70zUP5OlATEiIIr8Mkp3"
  config.qiniu_secret_key = "tWrBex4x1tOaVbIp53YGAoz9351xcILlcoMXbwtL"
  config.qiniu_bucket = "cnnirvana"
  config.qiniu_bucket_domain = "cnnirvana.qiniudn.com"
end

configure :development do
  set :database , "sqlite3:blog.db"
  CarrierWave.configure do |config|
    config.storage = :qiniu
    config.qiniu_access_key = "S-i191j3raW9PbGfbmxq70zUP5OlATEiIIr8Mkp3"
    config.qiniu_secret_key = "tWrBex4x1tOaVbIp53YGAoz9351xcILlcoMXbwtL"
    config.qiniu_bucket = "cnnirvana"
    config.qiniu_bucket_domain = "cnnirvana.qiniudn.com"
  end
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
