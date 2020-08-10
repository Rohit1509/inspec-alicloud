# frozen_string_literal: true

require 'alicloud_backend'
require 'pry-byebug'

class AliCloudOssBucket < AliCloudResourceBase
  name 'alicloud_oss_bucket'
  desc 'Verifies settings for an AliCloud OSS Bucket'
  example "
    describe alicloud_oss_bucket(bucket_name: 'test_bucket') do
      it { should exist }
    end
  "

  attr_reader :region, :bucket_name

  def initialize(opts = {})
    opts = { bucket_name: opts } if opts.is_a?(String)
    super(opts)
    validate_parameters(required: [:bucket_name])

    @bucket_name = opts[:bucket_name]

    catch_alicloud_errors do
      @bucket = @alicloud.oss_client.get_bucket(opts[:bucket_name])
    end
  end

  def exists?
    # @bucket object itself will not be nil if the bucket doesn't exist
    # need to check some property of the bucket and rescue the Bucket doesn't exist error
    begin
      @bucket.acl
      true
    rescue Aliyun::OSS::ServerError
      false
    end
  end

  def public?
    return false unless exists?
    @bucket.acl != 'private'
  end

  def has_access_logging_enabled?
    return false unless exists?
    @bucket.logging.enable == true
  end

  def has_default_encryption_enabled?
    return false unless exists?

    begin
      !@bucket.encryption.sse_algorithm.empty?
    rescue Aliyun::OSS::ServerError
      false
    end
  end

  def has_versioning_enabled?
    return false unless exists?
    @bucket.versioning.enable == true
  end

  def has_website_enabled?
    return false unless exists?
    @bucket.website.enable == true
  end

  def bucket_lifecycle_rules
    return false unless exists?
    @bucket.lifecycle
  end

  def to_s
    "OSS Bucket #{@bucket_name}"
  end
end
