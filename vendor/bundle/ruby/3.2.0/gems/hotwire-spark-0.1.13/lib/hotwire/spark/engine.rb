require "action_cable/server/base"
require "hotwire/spark/default_options"

module Hotwire::Spark
  class Engine < ::Rails::Engine
    isolate_namespace Hotwire::Spark

    config.hotwire = ActiveSupport::OrderedOptions.new unless config.respond_to?(:hotwire)
    config.hotwire.spark = ActiveSupport::OrderedOptions.new
    config.hotwire.spark.merge! Hotwire::Spark::DefaultOptions.new.to_h

    initializer "hotwire_spark.config" do |application|
      config.hotwire.spark.each do |key, value|
        Hotwire::Spark.send("#{key}=", value)
      end
    end

    initializer "hotwire_spark.assets" do |application|
      application.config.assets.precompile << "hotwire_spark.js"
    end

    initializer "hotwire_spark.install" do |application|
      Hotwire::Spark.install_into application if Hotwire::Spark.enabled?
    end
  end
end
