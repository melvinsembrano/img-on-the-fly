require "sinatra/base"
require_relative "./lib/iotf"

class App < Sinatra::Base
  register Sinatra::ConfigFile
  set :sessions, true
  enable :logging

  get "/*" do
    unless request.path.match(/__sinatra__/)
      begin
        iotf = Iotf::Processor.new(params)
        iotf.execute!
        send_file iotf.final_path
      rescue => err
        logger.error err
        status 404
      end
    end
  end
end
