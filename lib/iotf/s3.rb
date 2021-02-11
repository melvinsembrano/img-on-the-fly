require 'aws'

class Iotf::S3
  attr_accessor :client

  def initialize(config)
    
    if config[:aws_endpoint]
      Aws.config.update({
        endpoint: config[:aws_endpoint]
      })
    end
  end

  def download(key)
  end

end