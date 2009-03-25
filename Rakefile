require "rubygems"
require "rake/gempackagetask"
require "rake/clean"

$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'

require "nginx_stat"

spec = Gem::Specification.new do |s|
  s.name         = "nginx-stat"
  s.version      = NginxStat::VERSION
  s.author       = "Bryan Helmkamp"
  s.email        = "bryan" + "@" + "brynary.com"
  s.homepage     = "http://github.com/brynary/nginx-stat"
  s.summary      = "Watch live nginx stats"
  s.description  = s.summary
  s.executables  = "nginx_stat"
  s.files        = %w[Rakefile README.rdoc] + Dir["lib/**/*"]
  
  # rdoc
  s.has_rdoc         = true
  s.extra_rdoc_files = %w(README.rdoc)
end

Rake::GemPackageTask.new(spec) do |package|
  package.gem_spec = spec
end

desc 'Install the package as a gem.'
task :install => [:clean, :package] do
  gem = Dir['pkg/*.gem'].first
  sh "sudo gem install --no-rdoc --no-ri --local #{gem}"
end