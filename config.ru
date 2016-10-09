require 'rack'
require 'rack/cache'
require 'redis-rack-cache'

require './site/app'

use Rack::Cache,
  metastore:   'redis://localhost:6379/0/metastore',
  entitystore: 'redis://localhost:6379/0/metastore',
  verbose:     true,
  default_ttl: 60*24*7

run MyApp