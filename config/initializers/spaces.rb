require "aws-sdk-s3"

SPACES_CLIENT = Aws::S3::Client.new(
  access_key_id:     ENV["DO_SPACES_KEY"],
  secret_access_key: ENV["DO_SPACES_SECRET"],
  endpoint:          ENV["SPACES_ENDPOINT"],
  region:            ENV["SPACES_REGION"]
)
