# frozen_string_literal: true

require "test_helper"
require 'moderation_label_analyzer/analyzer'

class ModerationLabelAnalyzerTest < ActiveSupport::TestCase
  def setup
    @integration = ENV['INTEGRATION_TEST'].present?

    Rails.application.config.active_storage.analyzers.unshift ModerationLabelAnalyzer::Analyzer

    ModerationLabelAnalyzer.client_options = { region: 'ap-northeast-1' }
    @client = Aws::Rekognition::Client.new(
      region: 'ap-northeast-1'
      # credentials: nil,
    )

    @user = User.create!(name: 'ykpythemind')
  end

  def with_s3_upload(&block)
    block.call
  ensure
    if @user.photo.attached?
      @user.photo.purge
      puts 's3 object purged'
    end
  end

  def test_that_it_has_a_version_number
    refute_nil ::ModerationLabelAnalyzer::VERSION
  end

  def test_s3_alcohol_object
    with_s3_upload do
      @user.photo.attach(io: fixture_file_upload('beer.jpg'), filename: 'Beer')
      @user.save!

      analyzer = ModerationLabelAnalyzer.new(client: @client)
      result = analyzer.analyze(@user.photo.blob)

      assert result.harmful?
      assert result.response.moderation_labels.pluck(:name).all? { _1.include?('Alcohol') }
    end
  end

  def test_s3_normal_object
    with_s3_upload do
      @user.photo.attach(io: fixture_file_upload('ykpythemind.jpg'), filename: 'misakichan')
      @user.save!

      analyzer = ModerationLabelAnalyzer.new(client: @client)
      result = analyzer.analyze(@user.photo.blob)

      assert_not result.harmful?
    end
  end

  def test_local_object
    @user.avatar = fixture_file_upload('beer.jpg')
    @user.save!

    analyzer = ModerationLabelAnalyzer.new(client: @client)

    result = analyzer.analyze(@user.avatar.blob)
    assert result.harmful?
  end

  def test_local_object_with_custom_judgement
    @user.avatar = fixture_file_upload('beer.jpg')
    @user.save!

    judge = proc do |response|
      # alcohol is good. not harmful
      labels = response.moderation_labels
      labels.reject! { _1.name.downcase.include?('alcohol') }

     labels.size > 0 ? ::ModerationLabelAnalyzer::Judgement.new(harmful: true) : nil
    end

    analyzer = ModerationLabelAnalyzer.new(client: @client, judge: judge)

    result = analyzer.analyze(@user.avatar.blob)
    assert_not result.harmful?
  end

  def test_analyzable
    @user.avatar = fixture_file_upload('beer.jpg')
    @user.save!

    @user.avatar.blob.analyze
    @user.reload

    assert @user.avatar.analyzed?
    assert @user.avatar.metadata[:harmful]
  end
end
