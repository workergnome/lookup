require 'rack'
require 'rack/cache'
require 'redis-rack-cache'


redis_uri = ENV["REDIS_URL"] || "localhost:6379"

use Rack::Cache,
  metastore:   "redis://#{redis_uri}/0/metastore",
  entitystore: "redis://#{redis_uri}/0/metastore",
  verbose:     true,
  default_ttl: 60*24*7,
  allow_reload: true

require "rack/cors"

use Rack::Cors do
  allow do
    origins '*'
    resource '*', :headers => :any, :methods => [:get, :options, :head]
  end
end

require './site/app'

run MyApp