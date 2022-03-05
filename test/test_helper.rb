# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "moderation_label_analyzer"

require "minitest/autorun"

require "bundler/setup"
require "active_support"
require "active_support/test_case"
require "active_support/core_ext/object/try"
require "active_support/testing/autorun"

ENV["RAILS_ENV"] ||= "test"

require_relative "dummy/config/environment.rb"

require "active_job"
ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = ActiveSupport::Logger.new(nil)

require "tmpdir"


Rails.configuration.active_storage.service_configurations = {
  "local" => { "service" => "Disk", "root" => Dir.mktmpdir("active_storage_tests") },
  "s3" => { service: 's3', access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'], region: 'ap-northeast-1', bucket: 'moderation-label-analyzer-test' }
}.deep_stringify_keys

Rails.configuration.active_storage.service = "local"

ActiveStorage.logger = ActiveSupport::Logger.new(nil)
ActiveStorage.verifier = ActiveSupport::MessageVerifier.new("Testing")

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures
  self.fixture_path = File.expand_path("fixtures", __dir__)


  def fixture_file_upload(filename)
    Rack::Test::UploadedFile.new(
      Pathname.new(File.join(fixture_path, filename)).to_s
    )
  end
end

require "global_id"
GlobalID.app = "ActiveStorageExampleApp"

require ActiveStorage::Engine.root.join("db/migrate/20170806125915_create_active_storage_tables.rb").to_s

ActiveRecord::Schema.define do
  CreateActiveStorageTables.new.change

  create_table :users, force: true do |t|
    t.string :name
    t.timestamps
  end
end

class User < ActiveRecord::Base
  validates :name, presence: true

  has_one_attached :avatar, service: :local
  has_one_attached :photo, service: :s3
end
