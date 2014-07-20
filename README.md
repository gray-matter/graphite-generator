Graphite boards generator
=========================

## Prerequisites
Before using this script, you will need at least:
* Ruby
* The graphite-dashboard-api gem (gem install graphite-dashboard-api)

## The idea
Creating and updating Graphite dashboards is ~~painful~~
challenging. Well...yes, you may use the dashboard edition feature.

But when it comes to updating a dozen boards, with tons of tricky expressions,
you'd wish for an automated way of doing it. This is *exactly* what the Graphite
boards generator is intended for.

## Dead-simple configuration
### The "dashboards" node
The outmost dashboards configuration node is the "dashboards" entry. Beneath it,
the following properties are valid:
* name *(required)*: the dashboard name to which this will be saved if the graph
definition is valid
* width: the dashboard graphs width
* height: the dashboard graphs height
* graphs *(required)*: a list of dashboard graphs definition (explained below)

### The "graphs" node
Graphs are defined using the following properties:
* title: the displayed graph title
* targets *(required)*: a list of Graphite-compliant targets information
(explained below)

### The "targets" node
This is the heart of the configuration file. Here you may define:
* expression *(required)*: the bare Graphite expression
* extra_options: a dictionary of Graphite extra options (areaMode, hideLegend,
...)
* legend: the target curve legend
* color: the target curve color (whichever color is understood by Graphite)

The last two items are pure sugar and come down to using the *alias* and
*color* Graphite functions in the expression item.

### Example
The simplest working configuration example may be found
[here](/examples/dead-simple.json).

## Templates and multiplexing
### Basics
Most of the time, two graphs or dashboards only differ by a few slight
changes. For example, instead of writing:
```json
"targets":
[
    {
        "expression": "my.supa.expression",
        "legend": "It's supa !"
    },
    {
        "expression": "my.dupa.expression",
        "legend": "It's dupa !"
    }
]
```

You might find it more convenient to write:
```json
"targets":
[
    {
        "expression": "my.#awesomeness_key#.expression",
        "legend": "#awesomeness_legend#"
    }
]
```

Then you would need to list the available contexts for the replacements to
happen. This is done like this ("replacements" being at the same level as the
"dashboards" node):
```json
"replacements":
[
    "awesomeness":
    [
        {
             "awesomeness_key": "supa",
             "awesomeness_legend": "It's supa !"
        },
        {
             "awesomeness_key": "dupa",
             "awesomeness_legend": "It's dupa !"
        }
    ]
]
```

Finally, you will need to specify the places where the multiplexing should
happen. The "targets" node then becomes:
```json
"targets":
[
    {
        "multiplexers": ["awesomeness"],
        "expression": "my.#awesomeness_key#.expression"
    }
]
```

The values in "multiplexers" being the keys in the "replacements"
dictionary. In this example, two targets instances will be created, each one
having their own value of "#awesomeness_key#" and "#awesomeness_legend#"
available for use.

One may use the replacements in any value beneath the multiplexers declaration,
even in the width and height fields for example.

### Where to put multiplexers
One may define multiplexers exhaustively for:
* Dashboards
* Graphs
* Graph targets

When defining multiplexers for a given scope, the replacements are available for
the current level and its subscopes (eg. defining a multiplexer for dashboards
makes its replacements available for itself and both the graphs and graph
targets).

### Combining multiplexers
One may define more than one multiplexer to combine their effects and
cardinality.

For example, let's add these replacements:
```json
"awesomeness_precision":
[
    {
        "awesomeness_precision_key": "uber"
    },
    {
        "awesomeness_key": "fantastic",
    }
]
```

And modify the targets like this:
```json
"targets":
[
    {
        "multiplexers": ["awesomeness", "awesomeness_precision"],
        "expression": "my.#awesomeness_key#.#awesomeness_precision_key#.expression",
        "legend": "#awesomeness_legend#"
    }
]
```

Multiplexers will be combined in the order in which they are declared, meaning
that, in this case, the expression combinations will be:
```
my.supa.uber.expression
my.supa.fantastic.expression
my.dupa.uber.expression
my.dupa.fantastic.expression
```
### Example
A comprehensive example of multiplexers usage is available
[here](/examples/multiplexers.json).
