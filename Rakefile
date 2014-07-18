
require "bundler/gem_tasks"
require "rake/testtask"

desc "Build the gem and package it as a deb file"
task :build_deb do
  file_name = File.basename(Bundler::GemHelper.instance.build_gem)
  Dir.chdir("pkg")
  `gem2deb #{file_name}`
  Dir.chdir("..")
end

Rake::TestTask.new do |t|
  t.libs << 'lib/'
  t.libs << 'test/'
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end
