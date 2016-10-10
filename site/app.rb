# Standard Library
require "json"
require 'digest/sha1'

# Sinatra & Extensions
require 'sinatra/base'
require "sinatra/reloader" 
require "sinatra/json"

require 'sparql/client'



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

    set :context, <<~eos
      {
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
      eos

    set :frame, <<~eos
      {
        "@explicit": true,
        "@context": #{JSON.parse(settings.context)['@context'].to_json},
        "label":  {},
        "id": {},  
        "source": {},
        "agent":  {},
        "website": {}
      }
  eos
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

    query = "
      PREFIX skos:   <http://www.w3.org/2004/02/skos/core#>
      PREFIX foaf:   <http://xmlns.com/foaf/0.1/>
      PREFIX schema: <http://schema.org/>
      PREFIX dc:     <http://purl.org/dc/elements/1.1/>
      PREFIX rdfs:   <http://www.w3.org/2000/01/rdf-schema#>


      CONSTRUCT {
        ?entity skos:prefLabel ?label ;
                skos:inScheme  ?scheme ;
                foaf:focus     ?agent ;
                schema:url     ?website .
      }
      WHERE {
        ?entity dc:identifier  \"#{params[:id]}\" ; 
                skos:prefLabel ?label .
        OPTIONAL {
          ?entity skos:inScheme  ?scheme ;
        }
        OPTIONAL {
          ?entity foaf:focus   ?agent .
        }
        OPTIONAL {
          {
            ?entity schema:url ?website.
          } UNION {
            ?entity rdfs:seeAlso ?website.
          }
        }
      }
    "

    result = settings.getty_sparql.query(query)

    result.each_statement do |statement|
      puts statement.inspect
    end


    temp_object = {
        "label": "Couture, Thomas",
           "id": "http://vocab.getty.edu/ulan/500115403",
       "source": "http://vocab.getty.edu/ulan/",
        "agent": "http://vocab.getty.edu/ulan/500115403-agent",
      "website": "http://www.getty.edu/vow/ULANFullDisplay?find=&subjectid=500115403"
    }


    cache_control :public
    etag Digest::SHA1.hexdigest(temp_object.to_json)
    headers "Link" => "<http://#{request.host_with_port}/context>; rel=\"http://www.w3.org/ns/json-ld#context\"; type=\"application/ld+json\""

    json temp_object

  end

end








