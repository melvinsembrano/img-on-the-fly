require "sinatra/base"
require_relative "./lib/iotf"

class App < Sinatra::Base
  register Sinatra::ConfigFile
  set :sessions, true
  enable :logging

  get "/*" do
    unless request.path.match(/__sinatra__/)
      logger.info("Process request: #{ params }")

      begin
        iotf = Iotf::Processor.new(params)
        processed_file_path = iotf.execute!

        cache_control :public, max_age: 86400
        send_file processed_file_path
      rescue => err
        logger.error err
        status 404
        "File not found"
      end
    end
  end
end
