# data.rb

require 'sinatra'
require 'graphql'
require 'json'
require 'apollo-federation'
require 'webrick'

# Define your GraphQL schema
class BaseArgument < GraphQL::Schema::Argument
  include ApolloFederation::Argument
end

class BaseField < GraphQL::Schema::Field
  include ApolloFederation::Field

  argument_class BaseArgument
end

class BaseObject < GraphQL::Schema::Object
  include ApolloFederation::Object

  field_class BaseField
end
#
class ProductType < BaseObject
  include ApolloFederation::Object

  key fields: :id
  
  field :id, String, null: false, external: false
  field :name, String, null: false

  def self.resolve_reference(ref, _ctx)
    id = ref[:id]
    { id: id, name: "Mug #{id}"}
  end
end

class MySchema < GraphQL::Schema
  include ApolloFederation::Schema
  federation version: '2.0'
  use ApolloFederation::Tracing
  orphan_types ProductType
end

# Define a simple Sinatra app to handle the GraphQL requests
class MyApp < Sinatra::Base
  before do
    content_type 'application/json'
  end

  post '/graphql' do
    request_payload = JSON.parse(request.body.read)
    result = MySchema.execute(request_payload['query'], variables: request_payload['variables'])
    status 200
    p result.to_json
  end
end

puts "*"*20
schema = MySchema.federation_sdl
puts schema
File.open('data.schema', 'w') { |file| file.write(schema) }
puts "*"*20