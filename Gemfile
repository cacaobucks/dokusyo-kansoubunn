source "https://rubygems.org"

ruby "3.2.2"

# === Core ===
gem "rails", "~> 7.1.3"
gem "sqlite3", "~> 1.4"
gem "puma", ">= 6.0"
gem "bootsnap", require: false

# === Frontend ===
gem "sprockets-rails"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"

# === Authentication ===
gem "devise", "~> 4.9"

# === Image Processing ===
gem "image_processing", "~> 1.12"

# === Pagination ===
gem "kaminari"

# === Performance ===
gem "rack-mini-profiler"

# === Background Jobs ===
gem "redis", ">= 5.0"

group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "web-console"
  gem "error_highlight", ">= 0.4.0", platforms: [:ruby]
  gem "listen", "~> 3.8"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
end

# Windows/JRuby
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
