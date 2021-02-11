require "aws-sdk-s3"
require_relative "../../config/s3_config"
require 'fileutils'

module Iotf
  class S3
    include S3Config
    attr_accessor :client

    def initialize
      credentials = Aws::Credentials.new(s3_credentials[:access_key_id], s3_credentials[:s3_secret_access_key])
      aws_config = s3_client_config.merge({ credentials: credentials }).transform_keys { |k| k.to_sym }
      @client = Aws::S3::Client.new(aws_config)
    end

    def download(key)
      target_path = File.join(download_folder, key)
      setup_target_folder target_path

      get_params = {
        bucket: s3_bucket,
        key: key,
        response_target: target_path
      }
      client.get_object(get_params)

      target_path
    end

    def setup_target_folder(path)
      file_folder = File.dirname(path)
      FileUtils.mkdir_p(file_folder) unless File.exist?(file_folder)
    end
  end
end
