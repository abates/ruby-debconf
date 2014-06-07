
require "bundler/gem_tasks"

desc "Build the gem and package it as a deb file"
task :build_deb do
  file_name = File.basename(Bundler::GemHelper.instance.build_gem)
  Dir.chdir("pkg")
  `gem2deb #{file_name}`
  Dir.chdir("..")
end
