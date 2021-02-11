require "sinatra/base"

class App < Sinatra::Base
  register Sinatra::ConfigFile
  set :sessions, true
  enable :logging

  config_file "config/app.yml"

  get "/*" do
    "Hello world #{params.inspect} ----- #{ settings.aws.inspect }"
  end

end
