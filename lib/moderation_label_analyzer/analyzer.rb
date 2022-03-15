class ModerationLabelAnalyzer
  class Analyzer < ::ActiveStorage::Analyzer::ImageAnalyzer
    def self.accept?(blob)
      blob.image?
    end

    def self.client
      @client ||= Aws::Rekognition::Client.new(**ModerationLabelAnalyzer.client_options)
    end

    def metadata
      super.merge(analyze_moderation_labels)
    end

    private

    def analyze_moderation_labels
      analyzer = ModerationLabelAnalyzer.new(client: self.class.client)

      result = analyzer.analyze(blob)

      {
        harmful: result.harmful?,
        moderation_labels: result.response.moderation_labels.map { convert_moderation_label(_1) }
      }
    end

    def convert_moderation_label(moderation_label)
      {
        confidence: moderation_label.confidence,
        name: moderation_label.name,
        parent_name: moderation_label.parent_name
      }
    end
  end
end
