# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::S3

  class BucketLifecycle

    extend Aws::Deprecations

    # @overload def initialize(bucket_name, options = {})
    #   @param [String] bucket_name
    #   @option options [Client] :client
    # @overload def initialize(options = {})
    #   @option options [required, String] :bucket_name
    #   @option options [Client] :client
    def initialize(*args)
      options = Hash === args.last ? args.pop.dup : {}
      @bucket_name = extract_bucket_name(args, options)
      @data = options.delete(:data)
      @client = options.delete(:client) || Client.new(options)
      @waiter_block_warned = false
    end

    # @!group Read-Only Attributes

    # @return [String]
    def bucket_name
      @bucket_name
    end

    # Container for a lifecycle rule.
    # @return [Array<Types::Rule>]
    def rules
      data[:rules]
    end

    # @!endgroup

    # @return [Client]
    def client
      @client
    end

    # Loads, or reloads {#data} for the current {BucketLifecycle}.
    # Returns `self` making it possible to chain methods.
    #
    #     bucket_lifecycle.reload.data
    #
    # @return [self]
    def load
      resp = Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        @client.get_bucket_lifecycle(bucket: @bucket_name)
      end
      @data = resp.data
      self
    end
    alias :reload :load

    # @return [Types::GetBucketLifecycleOutput]
    #   Returns the data for this {BucketLifecycle}. Calls
    #   {Client#get_bucket_lifecycle} if {#data_loaded?} is `false`.
    def data
      load unless @data
      @data
    end

    # @return [Boolean]
    #   Returns `true` if this resource is loaded.  Accessing attributes or
    #   {#data} on an unloaded resource will trigger a call to {#load}.
    def data_loaded?
      !!@data
    end

    # @deprecated Use [Aws::S3::Client] #wait_until instead
    #
    # Waiter polls an API operation until a resource enters a desired
    # state.
    #
    # @note The waiting operation is performed on a copy. The original resource
    #   remains unchanged.
    #
    # ## Basic Usage
    #
    # Waiter will polls until it is successful, it fails by
    # entering a terminal state, or until a maximum number of attempts
    # are made.
    #
    #     # polls in a loop until condition is true
    #     resource.wait_until(options) {|resource| condition}
    #
    # ## Example
    #
    #     instance.wait_until(max_attempts:10, delay:5) do |instance|
    #       instance.state.name == 'running'
    #     end
    #
    # ## Configuration
    #
    # You can configure the maximum number of polling attempts, and the
    # delay (in seconds) between each polling attempt. The waiting condition is
    # set by passing a block to {#wait_until}:
    #
    #     # poll for ~25 seconds
    #     resource.wait_until(max_attempts:5,delay:5) {|resource|...}
    #
    # ## Callbacks
    #
    # You can be notified before each polling attempt and before each
    # delay. If you throw `:success` or `:failure` from these callbacks,
    # it will terminate the waiter.
    #
    #     started_at = Time.now
    #     # poll for 1 hour, instead of a number of attempts
    #     proc = Proc.new do |attempts, response|
    #       throw :failure if Time.now - started_at > 3600
    #     end
    #
    #       # disable max attempts
    #     instance.wait_until(before_wait:proc, max_attempts:nil) {...}
    #
    # ## Handling Errors
    #
    # When a waiter is successful, it returns the Resource. When a waiter
    # fails, it raises an error.
    #
    #     begin
    #       resource.wait_until(...)
    #     rescue Aws::Waiters::Errors::WaiterFailed
    #       # resource did not enter the desired state in time
    #     end
    #
    # @yieldparam [Resource] resource to be used in the waiting condition.
    #
    # @raise [Aws::Waiters::Errors::FailureStateError] Raised when the waiter
    #   terminates because the waiter has entered a state that it will not
    #   transition out of, preventing success.
    #
    #   yet successful.
    #
    # @raise [Aws::Waiters::Errors::UnexpectedError] Raised when an error is
    #   encountered while polling for a resource that is not expected.
    #
    # @raise [NotImplementedError] Raised when the resource does not
    #
    # @option options [Integer] :max_attempts (10) Maximum number of
    # attempts
    # @option options [Integer] :delay (10) Delay between each
    # attempt in seconds
    # @option options [Proc] :before_attempt (nil) Callback
    # invoked before each attempt
    # @option options [Proc] :before_wait (nil) Callback
    # invoked before each wait
    # @return [Resource] if the waiter was successful
    def wait_until(options = {}, &block)
      self_copy = self.dup
      attempts = 0
      options[:max_attempts] = 10 unless options.key?(:max_attempts)
      options[:delay] ||= 10
      options[:poller] = Proc.new do
        attempts += 1
        if block.call(self_copy)
          [:success, self_copy]
        else
          self_copy.reload unless attempts == options[:max_attempts]
          :retry
        end
      end
      Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        Aws::Waiters::Waiter.new(options).wait({})
      end
    end

    # @!group Actions

    # @example Request syntax with placeholder values
    #
    #   bucket_lifecycle.delete({
    #     expected_bucket_owner: "AccountId",
    #   })
    # @param [Hash] options ({})
    # @option options [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the request
    #   fails with the HTTP status code `403 Forbidden` (access denied).
    #
    #   <note markdown="1"> This parameter applies to general purpose buckets only. It is not
    #   supported for directory bucket lifecycle configurations.
    #
    #    </note>
    # @return [EmptyStructure]
    def delete(options = {})
      options = options.merge(bucket: @bucket_name)
      resp = Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        @client.delete_bucket_lifecycle(options)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   bucket_lifecycle.put({
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256, CRC64NVME
    #     lifecycle_configuration: {
    #       rules: [ # required
    #         {
    #           expiration: {
    #             date: Time.now,
    #             days: 1,
    #             expired_object_delete_marker: false,
    #           },
    #           id: "ID",
    #           prefix: "Prefix", # required
    #           status: "Enabled", # required, accepts Enabled, Disabled
    #           transition: {
    #             date: Time.now,
    #             days: 1,
    #             storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR
    #           },
    #           noncurrent_version_transition: {
    #             noncurrent_days: 1,
    #             storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR
    #             newer_noncurrent_versions: 1,
    #           },
    #           noncurrent_version_expiration: {
    #             noncurrent_days: 1,
    #             newer_noncurrent_versions: 1,
    #           },
    #           abort_incomplete_multipart_upload: {
    #             days_after_initiation: 1,
    #           },
    #         },
    #       ],
    #     },
    #     expected_bucket_owner: "AccountId",
    #   })
    # @param [Hash] options ({})
    # @option options [String] :content_md5
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    # @option options [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the request
    #   when you use the SDK. This header will not provide any additional
    #   functionality if you don't use the SDK. When you send this header,
    #   there must be a corresponding `x-amz-checksum` or `x-amz-trailer`
    #   header sent. Otherwise, Amazon S3 fails the request with the HTTP
    #   status code `400 Bad Request`. For more information, see [Checking
    #   object integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @option options [Types::LifecycleConfiguration] :lifecycle_configuration
    # @option options [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the account ID that
    #   you provide does not match the actual owner of the bucket, the request
    #   fails with the HTTP status code `403 Forbidden` (access denied).
    # @return [EmptyStructure]
    def put(options = {})
      options = options.merge(bucket: @bucket_name)
      resp = Aws::Plugins::UserAgent.metric('RESOURCE_MODEL') do
        @client.put_bucket_lifecycle(options)
      end
      resp.data
    end

    # @!group Associations

    # @return [Bucket]
    def bucket
      Bucket.new(
        name: @bucket_name,
        client: @client
      )
    end

    # @deprecated
    # @api private
    def identifiers
      { bucket_name: @bucket_name }
    end
    deprecated(:identifiers)

    private

    def extract_bucket_name(args, options)
      value = args[0] || options.delete(:bucket_name)
      case value
      when String then value
      when nil then raise ArgumentError, "missing required option :bucket_name"
      else
        msg = "expected :bucket_name to be a String, got #{value.class}"
        raise ArgumentError, msg
      end
    end

    class Collection < Aws::Resources::Collection; end
  end
end
