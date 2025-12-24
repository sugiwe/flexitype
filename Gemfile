source "https://rubygems.org"

gem "bootsnap", require: false
gem "google-id-token"
gem "image_processing", "~> 1.2"
gem "importmap-rails"
gem "jbuilder"
gem "kaminari"
gem "pg", "~> 1.1"
gem "propshaft"
gem "puma", ">= 5.0"
gem "rails", "~> 8.1.1"
gem "slim-rails"
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "thruster", require: false
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :production do
  gem "kamal", require: false
end

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "factory_bot_rails"
  gem "faker"
  gem "rspec-rails"
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

group :development do
  gem "web-console"
end
