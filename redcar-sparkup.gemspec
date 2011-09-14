Gem::Specification.new do |s|
  s.name = "redcar-sparkup"
  s.version = "1.0"
  s.platform = "ruby"
  s.authors = ["Aaron McLeod", "Pockata"]
  s.email = ["aaron.g.mcleod@gmail.com"]
  s.homepage = "http://github.com/agmcleod/redcar-sparkup"
  s.summary = "A plugin for redcar that uses the python sparkup utility."
  s.description = ""
  s.files = Dir.glob("{lib,assets}/**/*") + %w{README.md plugin.rb}
  s.require_path = 'lib'
end
