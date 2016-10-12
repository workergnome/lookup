# Standard Library
require "json"
require 'digest/sha1'

# Sinatra & Extensions
require 'sinatra/base'
require "sinatra/reloader" 
require "sinatra/json"

require 'sparql/client'

require "linkeddata"


require_relative "../lib/getty_query.rb"


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
    set :getty_sparql, SPARQL::Client.new("http://vocab.getty.edu/sparql")

    set :context, File.read("data/context.json")
    set :frame, File.read("data/frame.json")
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
    etag Digest::SHA1.hexdigest(settings.context)

    if request.accept? "application/ld+json"
      content_type "application/ld+json"
    else
      content_type "application/json"
    end
    
    settings.context
  end

  get "/frame" do
    cache_control :public
    etag Digest::SHA1.hexdigest(settings.frame)

    if request.accept? "application/ld+json"
      content_type "application/ld+json"
    else
      content_type "application/json"
    end
    
    settings.frame
  end


  get "/getty/:id" do

    cache_control :public, max_age: 86400

    querier = GettyQuery.new(settings.getty_sparql)

    ### THE RIGHT WAY TO DO IT
    # graph = querier.get_graph(params[:id])
    # unframed_json = JSON::LD::API::fromRdf(graph)
    # frame = JSON.parse(settings.frame)
    # json_results = JSON::LD::API.frame(unframed_json, frame)
    # result = json_results["@graph"]

    ### THE WRONG WAY TO DO IT
    result = querier.get_obj(params[:id])

    etag Digest::SHA1.hexdigest(result.to_json)
    headers "Link" => "<http://#{request.host_with_port}/context>; rel=\"http://www.w3.org/ns/json-ld#context\"; type=\"application/ld+json\""

    json result
  end

end








