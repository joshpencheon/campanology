require "rubygems"
require "active_support/core_ext/array"
require "pp"

unless Object.new.respond_to?(:require_relative, true)
  def require_relative(relative_feature)
    file = caller.first.split(/:\d/,2).first
    raise LoadError, "require_relative is called in #{$1}" if /\A\((.*)\)/ =~ file
    require File.expand_path(relative_feature, File.dirname(file))
  end
end

require_relative 'lib/extent'
require_relative 'lib/extent_finder'
require_relative 'lib/extent_checker'
require_relative 'lib/extent_builder'

require_relative 'lib/cycle_finder'
require_relative 'lib/change_finder'

require_relative 'lib/graph_builder'
require_relative 'lib/complete_graph'
require_relative 'lib/weighted_graph'

require_relative 'lib/midi_creator'

puts "**** [Recursive Extent Builder] ****"

extent = ExtentBuilder.new(6)
puts "Built extent recurively on #{extent.n} bells..."
puts "  number of row in extent: #{extent.rows.length}"
puts "  number of unique rows: #{extent.rows.uniq.length}"
puts "  valid extent?: #{ExtentChecker.new(extent).check}"

puts "**** [Graph Builder] ****"

puts "Building graph..."

# builder = GraphBuilder.new(4, [ 'x', '14', '12'])
# builder = GraphBuilder.new(7, [ 'x', '16', '12'])

# builder = GraphBuilder.new(6, [ 'x', '16', '12'])
builder = GraphBuilder.new(5, [ '345', '145', '125', '123'])

puts "  graph has #{builder.nodes.length} nodes."

puts "**** [Complete Graph] *****"

puts "Building complete graph over same nodes..."
complete = CompleteGraph.new(builder.nodes)

puts "  total adjacencies: " + complete.adjacencies.map { |k, v| v.length }.inject(0, &:+).to_s

puts " connected enough for cycle finding?: " + CycleFinder.new(complete.nodes, complete.adjacencies).conditions_met?.to_s

puts "**** [Hamiltonian Cycle Finding] ****"

finder = CycleFinder.from_graph_builder(builder)

puts "Original graph connected enough for guaranteed results?: " + finder.conditions_met?.to_s
# results = finder.seek!
# 
# cycles = []
# results.each do |starting_node, node_results|
#   node_results ||= {}
#   
#   (node_results[:cycles] || []).each do |cycle|
#     cycles << cycle
#   end
# end
# 
# puts "  cycle count: #{cycles.length}"
# puts "  valid cycle count: #{cycles.select { |cycle| ExtentChecker.new(cycle).check }.length}"
# puts "  unique cycle count: #{cycles.uniq.length}"

puts "**** [MIDI Sequencing] ****"

five_bells = ExtentBuilder.new(5)

pentatonic = ["Db4", "Eb4", "Gb4", "Ab4", "Bb4"]
tracks = []
3.times { |x| tracks << five_bells.tune(pentatonic.rotate(x)) }

MidiCreator.new(tracks).export!

puts "Extent MIDI outputted!"

puts "**** [Change finder] ****"

bell_count = 7
puts "On #{bell_count} bells, expect #{ChangeFinder.count_for(bell_count)} valid changes:"
ChangeFinder.new(8).valid_changes_in_notation.each_with_index { |change, index| puts "  #{index+1}:  #{change.inspect}" }

puts "**** [Weighted Graph - Prim's] ****"

puts "Arbitarily weighting original graph..."
weighted_adjacencies = {}
builder.adjacencies.each do |node, connections|
  weighted_adjacencies[node] ||= {} 

  connections.each do |other_node| 
    distance = [node, other_node].map { |n| n.join('').to_i }.inject(0, &:+)
    weighted_adjacencies[node][other_node] = distance
  end
end

weighted_graph = WeightedGraph.new(builder.nodes, weighted_adjacencies)

puts "Finding MST using Prim's algorithm..."
mst = weighted_graph.minimum_spanning_tree

puts "  MST has #{mst.nodes.length} nodes"
puts "  adjacency count: " + mst.adjacencies.map { |k, v| v.length }.inject(0, &:+).to_s

puts "**** [Weighted Graph - DIMACS] *****"

puts "Exporting weighted graph to file, using DIMAC formatting..."
 weighted_graph.to_dimacs("weighed_builder")
puts "...done!"

puts "************************"