require 'conf-reader'

class BoardGenerator
  def initialize(conf_reader, graphite_server, verbosity_level, dry_run)
    @conf_reader = conf_reader
    @graphite_server = graphite_server
    @verbosity_level = verbosity_level
    @dry_run = dry_run
  end

  def generate(conf_file_path, expression_checker)
    graphite_expression_checker = lambda do |metrics|
      return expression_checker.call(@graphite_server, metrics)
    end

    dashboards = @conf_reader.parse(conf_file_path, graphite_expression_checker, @verbosity_level > 1)
    reverse_index = dashboards.size()
    dashboards.each() do |dashboard|
      reverse_index -= 1

      if @verbosity_level > 1
        pretty_print_dasboard(dashboard)
      end

      if !@dry_run
        begin
          dashboard.save!(@graphite_server)

          if @verbosity_level > 0
            puts "Successfully created #{self.build_dashboard_url(dashboard.name)}"
          end
        rescue Exception => e
          $stderr.puts "ERROR: Could not create the dashboard #{dashboard.name} on #@graphite_server: #{e.message}"
        end
      end

      puts if @verbosity_level > 1 and reverse_index > 0
    end
  end

  def build_dashboard_url(dashboard_name)
    return "http://#@graphite_server/dashboard##{dashboard_name}"
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
