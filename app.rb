require "sinatra/base"

class App < Sinatra::Base
    set :sessions, true

    get "/" do
        "Hello world"
    end
end