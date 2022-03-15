# frozen_string_literal: true

require_relative "moderation_label_analyzer/version"

require 'aws-sdk-rekognition'
require 'base64'
require 'active_support/lazy_load_hooks'
require 'active_support/configurable'

class ModerationLabelAnalyzer
  include ActiveSupport::Configurable
  config_accessor :client_options

  def initialize(
    client:,
    judge: nil,
    detect_moderation_label_options: nil
  )
    @client = client
    @detect_moderation_label_options = detect_moderation_label_options

    @judge = judge || default_judge
  end

  def analyze(blob, options = detect_moderation_label_options)
    image_options =
      if blob.service.name == :s3
        {
          s3_object: {
            bucket: blob.service.bucket.name,
            name: blob.key
          }
        }
      else
        {
          bytes: blob.download
        }
      end

    detect_options = { image: image_options }.merge(options)

    response = client.detect_moderation_labels(detect_options)

    judgement = judge.call(response) || Judgement.new(harmful: false)
    judgement.response = response

    judgement
  end

  private

  attr_reader :client, :judge

  private

  def detect_moderation_label_options
    @detect_moderation_label_options ||
      {
        min_confidence: 1.0
      }
  end

  def default_judge
    # moderation_label_response is Array<Types::ModerationLabel> (https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Rekognition/Types/ModerationLabel.html)
    proc do |moderation_label_response|
      if moderation_label_response.moderation_labels.size > 0
        Judgement.new(harmful: true)
      else
        nil
      end
    end
  end

  Judgement = Struct.new(:harmful, :response, keyword_init: true) do
    def harmful?
      harmful
    end
  end
end

ActiveSupport.on_load(:active_storage) do
  require 'moderation_label_analyzer/analyzer'
end

if defined?(Rails)
  require 'moderation_label_analyzer/railtie'
end
