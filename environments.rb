CarrierWave.configure do |config|
  config.qiniu_access_key = ENV['QINIU_ACCESS_KEY']
  config.qiniu_secret_key = ENV['QINIU_SECRET_KEY']
  config.qiniu_bucket = "cnnirvana"
  config.qiniu_bucket_domain = "cnnirvana.qiniudn.com"
end

configure do
  I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
  I18n.load_path = Dir[File.join(settings.root, 'locales', '*yml')]
  I18n.backend.load_translations
  I18n.default_locale = :zh
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
