require "sinatra/base"

class App < Sinatra::Base
    set :sessions, true
    enable :logging

    get "/*" do
        "Hello world #{ params.inspect }"
    end
end