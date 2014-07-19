require 'conf-reader'

class BoardGenerator
  def initialize(conf_reader, graphite_server)
    @conf_reader = conf_reader
    @graphite_server = graphite_server
  end

  def generate(conf_file_path, expression_checker)
    graphite_expression_checker = lambda do |metrics|
      return expression_checker.call(@graphite_server, metrics)
    end

    dashboards = @conf_reader.parse(conf_file_path, graphite_expression_checker)
    dashboards.each() do |dashboard|
      dashboard.save!(@graphite_server)
    end
  end
end
