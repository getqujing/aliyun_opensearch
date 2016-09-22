$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "aliyun_opensearch/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "aliyun_opensearch"
  s.version     = OpenSearch::VERSION
  s.authors     = ["Zhou Rui"]
  s.email       = ["zhourui@getqujing.com"]
  s.homepage    = "https://github.com/getqujing/aliyun_opensearch"
  s.summary     = "Rails plugin for aliyun opensearch."
  s.description = "Rails plugin for aliyun opensearch."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.require_paths = ["lib"]

  s.add_dependency "rails", "~> 4.0.0"
  s.add_dependency "rest-client"
end
