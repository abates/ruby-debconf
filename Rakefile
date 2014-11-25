
require "rake/testtask"
require "bundler/gem_tasks"

Rake::TestTask.new do |t|
  t.libs << 'test/'
  t.libs << 'lib/'
  t.test_files = FileList['test/specs/*_spec.rb', 'test/specs/*_test.rb']
end
