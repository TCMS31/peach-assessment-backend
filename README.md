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
### CONTINUE HERE !!!!
```


### Environment Setup:
Rails master key needed to encrypt credentials. You can get it from @mskalra
```bash
echo "RAILS_MASTER_KEY={key}" >> .env
brew install rbenv
rbenv install
rvm install "ruby-3.1.0"
sudo gem install bundler:2.2.26
gem install bundler:2.2.26
bundle install
bin/rails db:prepare
```

### Run Migrations:
```
# TODO: ADD ME!
```

### Running:
```
rails s -b 0.0.0.0
```