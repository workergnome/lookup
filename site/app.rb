# Standard Library
require "json"
require 'digest/sha1'

# Sinatra & Extensions
require 'sinatra/base'
require "sinatra/reloader" 
require "sinatra/json"

# Linked Data Libraries
require 'sparql/client'
require "linkeddata"

# Internal Libraries
require_relative "../lib/getty_query.rb"


class MyApp < Sinatra::Base


  #  Development-Environment-specific configuration
  configure :development do
    register Sinatra::Reloader
    Dir.glob('./lib/**/*') { |file| also_reload file}
    set :show_exceptions, :after_handler
  end

  # Global configuration
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
    "
    <h1> Entity Lookup Service </h1>
    <p> This provides basic RDF information about an entity, suitable for embedding into a graph when an entity is reconciled.
    <h2> Example URLs </h2>
    <ul>
      <li> <a href='/getty/500012368.json'> /getty/500012368.json (as JSON, with JSON-LD header)</a>
      <li> <a href='/getty/500012368.jsonld'> /getty/500012368.json (as JSON-LD with context)</a>
      <li> <a href='/getty/500012368.rdf'> /getty/500012368.rdf  (as RDF/XML)</a>
      <li> <a href='/getty/500012368.ttl'> /getty/500012368.ttl (As Turtle)</a>
      <li> <a href='/getty/500012368'> /getty/500012368 (using content negotiation)</a>
    </ul>
    "
  end

  # The JSON-LD Context
  #----------------------------------------------------------------------------
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

  # The JSON-LD Frame
  #----------------------------------------------------------------------------
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


  # A lookup for a Getty ID
  #----------------------------------------------------------------------------
  get "/getty/:id.?:format?" do

    cache_control :public, max_age: 86400

    # Handle Content Negotiation
    if params[:format].nil?
      request.accept.each do |accept_obj|
        case accept_obj.to_s
        when"application/ld+json", "application/json"
          redirect to("#{request.url}.json"), 303
        when "text/turtle"
          redirect to("#{request.url}.ttl"), 303
        when "application/rdf+xml"
          redirect to("#{request.url}.rdf"), 303
        end
      end
      # default to JSON
      redirect to("#{request.url}.json"), 303
    end

    # Make the Query
    graph = GettyQuery.new(settings.getty_sparql).get_graph(params[:id])

    # Handle various formats
    case params[:format]

    when "jsonld"
      unframed_json = JSON::LD::API::fromRdf(graph)
      frame = JSON.parse(settings.frame)
      json_results = JSON::LD::API.frame(unframed_json, frame)

      content_type "application/ld+json"
      json_results.to_json
    when "json"

      headers "Link" => "<http://#{request.host_with_port}/context>; rel=\"http://www.w3.org/ns/json-ld#context\"; type=\"application/ld+json\""

      unframed_json = JSON::LD::API::fromRdf(graph)
      frame = JSON.parse(settings.frame)
      json_results = JSON::LD::API.frame(unframed_json, frame)
      
      json json_results["@graph"].count == 1 ? json_results["@graph"].first : json_results["@graph"]


    # Handle Turtle
    when "ttl"
      content_type "text/turtle"
      graph.dump(:turtle)  

    # Handle RDF/XML  
    when "rdf"
      content_type "application/rdf+xml"
      graph.dump(:rdfxml)         
    end
  end

end








