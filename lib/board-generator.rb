require 'conf-reader'

class BoardGenerator
  def initialize(conf_reader, graphite_server, verbose)
    @conf_reader = conf_reader
    @graphite_server = graphite_server
    @verbose = verbose
  end

  def generate(conf_file_path, expression_checker)
    graphite_expression_checker = lambda do |metrics|
      return expression_checker.call(@graphite_server, metrics)
    end

    dashboards = @conf_reader.parse(conf_file_path, graphite_expression_checker)
    reverse_index = dashboards.size()
    dashboards.each() do |dashboard|
      reverse_index -= 1

      if @verbose
        pretty_print_dasboard(dashboard)
        puts if reverse_index > 0
      end

      dashboard.save!(@graphite_server)
    end
  end

  def pretty_print_dasboard(dashboard)
    puts "- #{dashboard.name}"

    dashboard.graphs.each() do |graph|
      # FIXME when https://github.com/criteo/graphite-dashboard-api/pull/1 is merged
      puts "-- #{graph.to_hash['title']}"

      graph.targets.each() do |target|
        puts "--- #{target}"
      end

      graph.extra_options.each() do |opt_key, opt_value|
        puts "--- #{opt_key}: #{opt_value}"
      end
    end
  end
end
