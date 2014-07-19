Graphite boards generator
=========================

# Prerequisites
Before using this script, you will at least:
* Ruby
* The graphite-dashboard-api gem (gem install graphite-dashboard-api)

# The idea
Creating and updating Graphite dashboards is ~~painful~~
challenging. Well...yes, you may use the dashboard edition feature.

But when it comes to updating a dozen boards, with tons of tricky expressions,
you'd wish for an automated way of doing it. This is *exactly* what the Graphite
boards generator is intended for.

# Dead-simple configuration
## The "dashboards" node
The outmost dashboards configuration node is the "dashboards" entry. Beneath it,
the following properties are valid:
* name *(required)*: the dashboard name to which this will be saved if the graph
#definition is valid
* width: the dashboard graphs width
* height: the dashboard graphs height
* graphs *(required)*: a list of dashboard graphs definition (explained below)

## The "graphs" node
Graphs are defined using the following properties:
* title: the displayed graph title
* targets *(required)*: a list of Graphite-compliant targets information
(explained below)

## The "targets" node
This is the heart of the configuration file. Here you may define:
* expression *(required)*: the bare Graphite expression
* extra_options: a dictionary of Graphite extra options (areaMode, hideLegend,
...)
* legend: the target curve legend
* color: the target curve color (whichever color is understood by Graphite)

The two latest items are pure sugar and come down to using the *alias* and
*color* Graphite functions in the expression item.

## Example
The simplest working configuration example may be found
[here](/examples/dead-simple.json).
