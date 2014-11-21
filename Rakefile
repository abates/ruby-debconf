
#require "bundler/gem_tasks"
require "rake/testtask"

#desc "Build the gem and package it as a deb file"
#task :build_deb do
#  ENV['DH_RUBY_IGNORE_TESTS'] = 'all'
#  file_name = File.basename(Bundler::GemHelper.instance.build_gem)
#  Dir.chdir("pkg")
#  `gem2deb #{file_name}`
#  Dir.chdir("..")
#end

Rake::TestTask.new do |t|
  t.libs << 'test/'
  t.libs << 'lib/'
  t.test_files = FileList['test/specs/*_spec.rb', 'test/specs/*_test.rb']
end
