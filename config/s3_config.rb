require "json"
module S3Config

  def s3_credentials
    {
      access_key_id: ENV.fetch('S3_ACCESS_KEY_ID') { "key" },
      s3_secret_access_key: ENV.fetch('S3_SECRET_ACCESS_KEY') { "secret" },
    }
  end

  def s3_client_config
    JSON.parse ENV.fetch("S3_CLIENT_CONFIG") { 
      '{"force_path_style":true, "region":"us-west-2"}'
    }
  end

  def s3_bucket
    ENV["S3_BUCKET"]
  end

  def download_folder
    ENV.fetch("S3_DOWNLOAD_FOLDER") { "/tmp/iotf" }
  end

end