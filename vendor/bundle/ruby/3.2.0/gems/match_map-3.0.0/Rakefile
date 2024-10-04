# encoding: utf-8
begin
  require 'bundler'
rescue LoadError => e
  warn e.message
  warn "Run `gem install bundler` to install Bundler."
  exit -1
end

begin
  Bundler.setup(:development)
rescue Bundler::BundlerError => e
  warn e.message
  warn "Run `bundle install` to install missing gems."
  exit e.status_code
end

require 'rake'

require "bundler/gem_tasks"

require 'yard'
YARD::Rake::YardocTask.new  
task :doc => :yard

require 'rake/testtask'
Rake::TestTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => [:test]

desc "Run a quick benchmark"
task :bench do
  $: << 'lib'
  load 'bench/bench.rb'
end

