require "matrix"

require "rubygems"
require "active_support/core_ext/array"

require_relative 'extensions/matrix'

require_relative 'lib/extent'
require_relative 'lib/extent_finder'
require_relative 'lib/extent_checker'
require_relative 'lib/extent_builder'

require_relative 'lib/cycle_finder'

require_relative 'lib/graph_builder'

extent = ExtentBuilder.new(6)

puts "**** [STATS] ****"

puts "#rows: #{extent.rows.length}"
puts "#rows (uniq): #{extent.rows.uniq.length}"

puts "valid extent: #{ExtentChecker.new(extent).check}"

puts "*****************"

builder = GraphBuilder.new(4, [ 'x', '14', '12'])
# builder = GraphBuilder.new(7, [ 'x', '16', '12'])

# builder = GraphBuilder.new(6, [ 'x', '16', '12'])

puts builder.nodes.length

puts "*****************"

finder = CycleFinder.from_graph_builder(builder)
puts "done init..."
finder.seek!

puts "*****************"