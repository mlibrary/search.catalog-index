source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

group :development do
  gem "bundler"
  gem 'rake'
  gem 'rspec'
  gem 'webmock'
end

gem 'yell'

gem 'traject', '~>3.0'
gem 'traject_umich_format'
gem 'match_map'
gem 'traject_alephsequential_reader'
gem 'sequel'
gem 'httpclient'
gem 'library_stdnums'

if defined? JRUBY_VERSION
  gem 'naconormalizer'
  gem 'jdbc-mysql'
  gem 'psych'
  gem "traject-marc4j_reader", "~> 1.0"
  gem 'pry-debugger-jruby'
else
  gem 'mysql2'
end

gem 'marc-fastxmlwriter'
gem 'high_level_browse'

gem 'pry'


#For liblocyaml
gem 'alma_rest_client',
  git: 'https://github.com/mlibrary/alma_rest_client', 
  tag: '1.1.0'
