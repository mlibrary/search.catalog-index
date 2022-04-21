source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

group :development do
  gem "bundler", '~>2.0'
  gem 'rake', '~>13.0'
  gem 'rspec', '~>3.0'
  gem 'webmock', '~>3.0'
end

gem 'yell', '~>2.0'

gem 'traject', '~>3.0'
gem 'traject_umich_format', '~>0.4.0'
gem 'match_map', '~>3.0'
gem 'sequel', '~>5.0'
gem 'httpclient', '~>2.0'
gem 'library_stdnums', '~>1.0'

platforms :jruby do
  gem 'naconormalizer'
  gem 'jdbc-mysql', '~>8.0'
  gem 'psych'
  gem "traject-marc4j_reader", "~> 1.0"
  gem 'pry-debugger-jruby'
end

platforms :mri do
  gem 'mysql2'
end

gem 'marc-fastxmlwriter', '~>1.0'
gem 'high_level_browse', '=0.1.0'

gem 'pry'


#For liblocyaml
gem 'alma_rest_client',
  git: 'https://github.com/mlibrary/alma_rest_client', 
  tag: '1.1.0'
