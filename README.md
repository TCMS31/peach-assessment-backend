# peach-take-home-back-end

### Setup Postgres (note: use v @13)
Full instructions: https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-ruby-on-rails-application-on-macos
```bash
brew install postgresql@13
echo 'export PATH="/usr/local/opt/postgresql@13/bin:$PATH"' >> ~/.bash_profile
echo 'export PATH="/opt/homebrew/opt/postgresql@13/bin:$PATH"' >> ~/.zshrc
source ~/.bash_profile
brew services start postgresql@13
postgres -V
createdb
createuser -s -r peachtakehomebackend
```


### Environment Setup:
```bash
brew install rbenv
rbenv install
rvm install "ruby-3.1.0"
sudo gem install bundler:2.2.26
gem install bundler:2.2.26
bundle install
bin/rails db:prepare
RAILS_ENV=development
```

### Run Migrations & Seed DB:
```
rails db:migrate RAILS_ENV=development
bundle exec rake db:seed
```

### Run Server:
```
rails s -b 0.0.0.0
```

### Run Rails Console:
```
rails c
```

### Resetting DB:
```
rails db:reset && rails db:migrate
```
