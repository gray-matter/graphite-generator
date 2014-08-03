require 'graphite-dashboard-api'
require 'json'
require 'set'

class ConfReader
  protected
  DEFAULT_EXTRA_OPTIONS = {
    'fgcolor' => 'FFFFFF',
    'bgcolor' => '000000',
  }

  def build_replacement_scopes(multiplexers_scopes, multiplexers)
    return [{}] if multiplexers.nil?() or multiplexers.empty?()

    scopes = []
    children_scopes = self.build_replacement_scopes(multiplexers_scopes, multiplexers[1..-1])

    mx_scopes = multiplexers_scopes.fetch(multiplexers[0], {})
    mx_scopes.each() do |scope|
      children_scopes.each() do |children_scope|
        scopes << scope.merge(children_scope)
      end
    end

    return scopes
  end

  def apply_replacements(original_str, replacements)
    str = original_str.to_s().clone()

    replacements.each() do |pattern, replacement|
      str.gsub!("##{pattern}#", replacement.to_s())
    end

    return str
  end

  def generate_graph_targets(conf_targets, graph_scope,
                             replacements, expression_checker, verbose)
    targets = []

    conf_targets.each() do |curve|
      raw_expression = curve.fetch("expression", "0")
      raw_legend = curve.fetch("legend", "")
      raw_color = curve.fetch("color", "")

      curve_multiplexers = curve.fetch("multiplexers", [])
      curve_replacement_scopes = self.build_replacement_scopes(replacements, curve_multiplexers)

      curve_replacement_scopes.each() do |curve_scope|
        merged_scope = curve_scope.merge(graph_scope)

        expression = self.apply_replacements(raw_expression, merged_scope)
        legend = self.apply_replacements(raw_legend, merged_scope)
        color = self.apply_replacements(raw_color, merged_scope)

        final_expression = expression

        unless color.empty?()
          final_expression = "color(#{final_expression}, \"#{color}\")"
        end

        unless legend.empty?()
          final_expression = "alias(#{final_expression}, \"#{legend}\")"
        end

        if expression_checker.nil?() || expression_checker.call(expression)
          targets << final_expression
        else
          puts(expression + " doesn't seem to work, skipping") if verbose
        end
      end
    end

    return targets
  end

  def generate_graphs(dashboard_conf, dashboard_scope,
                      replacements, expression_checker, verbose)
    dashboard_graphs = []

    dashboard_conf.fetch("graphs", {}).each() do |graph|
      raw_title = graph.fetch("title", "")
      raw_min_value = graph.fetch("min", "")
      raw_max_value = graph.fetch("max", "")
      raw_extra_options = graph.fetch("extra_options", {})

      graph_multiplexers = graph.fetch("multiplexers", [])
      graph_replacement_scopes = self.build_replacement_scopes(replacements, graph_multiplexers)

      conf_targets = graph.fetch("targets", {})

      graph_replacement_scopes.each() do |graph_scope|
        merged_scope = graph_scope.merge(dashboard_scope)
        title = self.apply_replacements(raw_title, merged_scope)
        extra_options = raw_extra_options.clone()

        extra_options.each() do |extra_option|
          extra_option[1] = self.apply_replacements(extra_option[1], merged_scope)
        end

        graph_targets = self.generate_graph_targets(conf_targets, merged_scope,
                                                    replacements, expression_checker,
                                                    verbose)

        if graph_targets.empty?()
          $stderr.puts("The graph #{title} would be empty, not creating it")
        else
          dashboard_graphs << GraphiteDashboardApi::Graph.new() do
            targets graph_targets
            @title = title
            @extra_options = extra_options.merge(DEFAULT_EXTRA_OPTIONS)
          end
        end
      end
    end

    return dashboard_graphs
  end

  public
  def parse(file_path, expression_checker, verbose)
    conf = JSON.parse(IO.read(file_path))
    dashboards = []
    replacements = conf.fetch("replacements", {})
    dashboard_names = Set.new()

    conf.fetch("dashboards", []).each() do |dashboard_conf|
      raw_dashboard_name = dashboard_conf.fetch("name", "")
      raw_width = dashboard_conf.fetch("width", 400)
      raw_height = dashboard_conf.fetch("height", 250)

      dashboard_multiplexers = dashboard_conf.fetch("multiplexers", [])
      dashboard_replacement_scopes = self.build_replacement_scopes(replacements, dashboard_multiplexers)

      dashboard_replacement_scopes.each() do |dashboard_scope|
        dashboard_name = self.apply_replacements(raw_dashboard_name, dashboard_scope)
        width = self.apply_replacements(raw_width, dashboard_scope)
        height = self.apply_replacements(raw_height, dashboard_scope)

        if dashboard_name.empty?()
          puts "No dashboard name given, skipping" if verbose
          next
        end

        if dashboard_names.add?(dashboard_name).nil?()
          puts "Duplicate dashboard name ('#{dashboard_name}'), skipping" if verbose
          next
        end

        dashboard_graphs = self.generate_graphs(dashboard_conf, dashboard_scope,
                                                replacements, expression_checker,
                                                verbose)

        if dashboard_graphs.empty?()
          puts("The dashboard #{dashboard_name} would be empty, not creating it") if verbose
        else
          dashboards << GraphiteDashboardApi::Dashboard.new(dashboard_name) do
            graphs dashboard_graphs
            @graphSize_width = width
            @graphSize_height = height
            @timeConfig_relativeStartUnits = 'hours'
            @timeConfig_relativeStartQuantity = 4
            @defaultGraphParams_from = '-12hours'
          end
        end
      end
    end

    return dashboards
  end
end
