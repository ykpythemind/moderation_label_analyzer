module ModerationLabelAnalyzer
  class Railtie < ::Rails::Railtie
    ActiveSupport.on_load(:active_storage) do
      puts 'onload'
    end
  end
end
