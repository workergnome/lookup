class GettyQuery

  CONSTRUCT_QUERY = "
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
        ?entity dc:identifier  \"ID_VALUE_GOES_HERE\" ; 
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
        FILTER(LANG(?label) = \"\" || LANGMATCHES(LANG(?label), \"en\"))
      }
    "


  SELECT_QUERY = "
      PREFIX skos:   <http://www.w3.org/2004/02/skos/core#>
      PREFIX foaf:   <http://xmlns.com/foaf/0.1/>
      PREFIX schema: <http://schema.org/>
      PREFIX dc:     <http://purl.org/dc/elements/1.1/>
      PREFIX rdfs:   <http://www.w3.org/2000/01/rdf-schema#>

      SELECT ?label ?id ?source ?agent ?website 
      
      WHERE {
        ?id dc:identifier  \"ID_VALUE_GOES_HERE\" ; 
                skos:prefLabel ?label .
        OPTIONAL {
          ?id skos:inScheme  ?source ;
        }
        OPTIONAL {
          ?id foaf:focus ?agent .
        }
        OPTIONAL {
          {
            ?id schema:url ?website.
          } UNION {
            ?id rdfs:seeAlso ?website.
          }
        }
        FILTER(LANG(?label) = \"\" || LANGMATCHES(LANG(?label), \"en\"))
      }
    "


  def initialize(client)
    @client = client
  end


  def get_obj(id)
    query = SELECT_QUERY.gsub("ID_VALUE_GOES_HERE", id)
    results = @client.query(query)

    # Replace the arrays with literals if there is only one obj in the array
    results.bindings.inject({}) { |h, (k, v)| h[k] = v.uniq.count == 1 ? v.first : v; h }

  end

  def get_graph(id)

    graph = RDF::Graph.new
    query = CONSTRUCT_QUERY.gsub("ID_VALUE_GOES_HERE", id)
    results = @client.query(query)
    results.each_statement {|s| graph.insert s unless s.incomplete?}    

  end
end