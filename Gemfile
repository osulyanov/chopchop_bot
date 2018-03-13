source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.4'
gem 'pg', '~> 0.18'
gem 'puma', '~> 3.7'
# gem 'jbuilder', '~> 2.5'
gem 'redis-rails', '~> 5'
# gem 'bcrypt', '~> 3.1.7'
# gem 'rack-cors'
gem 'telegram-bot', github: 'telegram-bot-rb/telegram-bot', ref: '384d203'
gem 'faraday'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
end
