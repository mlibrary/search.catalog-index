require "bundler/gem_tasks"

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.pattern = "test/**/*_spec.rb"
  t.libs << "test"
end

task spec: :test
task default: :test
