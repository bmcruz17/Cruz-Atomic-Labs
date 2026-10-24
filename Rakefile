require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

desc "Build the site into _site/"
task :build do
  sh "bundle exec jekyll build"
end

desc "Build the site and check every link, including external ones (needs network)"
task proof_external: :build do
  require "html-proofer"
  HTMLProofer.check_directory("./_site", ignore_status_codes: [429]).run
end

task default: :test
