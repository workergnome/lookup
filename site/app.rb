# Standard Library
require "json"
require 'digest/sha1'

# Sinatra & Extensions
require 'sinatra/base'
require "sinatra/reloader" 
require "sinatra/json"


# # Internal Libraries
# require "./lib/plant_uml_encode64.rb"
# require "./lib/aac.rb"

class MyApp < Sinatra::Base


  configure :development do
    register Sinatra::Reloader
    Dir.glob('./lib/**/*') { |file| also_reload file}
    set :show_exceptions, :after_handler
  end

  configure do 
    set :context, {
        "@context": { 
          "skos":    "http://www.w3.org/2004/02/skos/core#",
          "foaf":   "http://xmlns.com/foaf/0.1/",
          "schema":  "http://schema.org/",
          "label":   "skos:prefLabel",
          "id":      "@id",
          "source": {
            "@id":   "skos:inScheme",
            "@type": "@id"
          },
          "agent":  {
            "@id":   "foaf:focus",
            "@type": "@id"
          }, 
          "website": {
            "@id":   "schema:url",
            "@type": "@id"
          }
        }
      }
  end
 

             #-------------------------------------------------#
             #                  ROUTES BELOW                   #
             #-------------------------------------------------#


  # Index Route
  #----------------------------------------------------------------------------
  get "/" do
    "TODO:  Write Instructions Here."
  end

  get "/context" do

    cache_control :public
    etag Digest::SHA1.hexdigest(settings.context.to_json)
    json settings.context


      

  end

  get "/getty" do

    temp_object = {
        "label": "Couture, Thomas",
           "id": "http://vocab.getty.edu/ulan/500115403",
       "source": "http://vocab.getty.edu/ulan/",
        "agent": "http://vocab.getty.edu/ulan/500115403-agent",
      "website": "http://www.getty.edu/vow/ULANFullDisplay?find=&subjectid=500115403"
    }

    cache_control :public
    etag Digest::SHA1.hexdigest(temp_object.to_json)
    headers "Link" => "<//#{request.host_with_port}/context>; rel=\"http://www.w3.org/ns/json-ld#context\"; type=\"application/ld+json\""
    puts "request.host_with_port: #{request.host_with_port}"

    json temp_object


  end

end








