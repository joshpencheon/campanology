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
require_relative 'lib/circuit_finder'
require_relative 'lib/change_finder'

require_relative 'lib/graph_builder'
require_relative 'lib/complete_graph'
require_relative 'lib/weighted_graph'

require_relative 'lib/matcher_interface'

require_relative 'lib/midi_creator'

# puts "----"
# tmp_n = 40
# tmp = WeightedGraph.new((1..tmp_n).to_a)
# 1.upto(tmp_n) do |i|
#   ((1..tmp_n).to_a - [i, (i-tmp_n) % tmp_n]).each do |j|
#     tmp.connect!(i,j,11)
#   end
# end
# circuit = CircuitFinder.new(tmp).seek!
# 
# puts circuit.uniq.sort == tmp.nodes.sort
# puts "#{circuit.length - 1}, #{tmp.edges.length}"
# 
# 1/0
# puts "----"

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
ChangeFinder.new(bell_count).valid_changes_in_notation.each_with_index { |change, index| puts "  #{index+1}:  #{change.inspect}" }

# puts "**** [Weighted Graph - Prim's] ****"
# 
# puts "Weighting original graph..."
# 
# weighted_graph = WeightedGraph.new(builder.nodes)
# 
# # Connect up vertices with used changes
# builder.adjacencies.keys.each_with_index do |node, index|
#   (builder.adjacencies[node] - builder.adjacencies.keys[0, index]).each do |other_node|
#     weighted_graph.connect!(node, other_node, 0.5)
#   end
# end
# 
# weighted_graph.nodes.each_with_index do |node, index|
#   weighted_graph.nodes[index+1, weighted_graph.nodes.length].each do |other_node|
#     if !builder.connected?(node, other_node)
#       if ExtentChecker.new([node, other_node]).check
#         weighted_graph.connect!(node, other_node, 0.51)
#       else
#         weighted_graph.connect!(node, other_node, 1)
#       end
#     end
#   end
# end
# 
# puts "  - has #{weighted_graph.nodes.length} nodes"
# puts "  - & #{weighted_graph.edges.length} adjs (#{weighted_graph.edges.uniq.length} uniq)"
# 
# puts "Finding MST using Prim's algorithm..."
# mst = weighted_graph.minimum_spanning_tree
# 
# puts "  MST has #{mst.nodes.length} nodes"
# puts "  adjacency count: " + mst.edges.length.to_s
# puts "  degree distribution: " + mst.nodes.map { |node| mst.connected_to(node).length }.uniq.inspect
# 
# mst.nodes.each { |node| puts node.to_s + ' ' + mst.connected_to(node).inspect }
# 
# puts "**** [Weighted Graph - DIMACS] *****"
# 
# puts "Exporting weighted graph to file, using DIMAC formatting..."
# weighted_graph.to_dimacs("weighted_builder")
# puts "...done!"
# 
# puts "**** [Weighted Graph - BLOSSOMING] *****"
# 
# # Create complete graph over the set of odd vertices in the MST
# odd_nodes = mst.nodes.select { |node| mst.connected_to(node).length % 2 == 1  }
# matching_target = WeightedGraph.new(odd_nodes)
# matching_target.complete! { |node1, node2| weighted_graph.distance_between(node1, node2) }
# 
# puts "  matching_target has #{matching_target.nodes.length} nodes"
# puts "  edges count: " + matching_target.edges.length.to_s
# 
# blossom_proxy = MatcherInterface.new(matching_target)
# 
# puts "blossoming..."
# matching = blossom_proxy.get_matching
# puts "  - got matching, with #{matching.nodes.length} nodes and #{matching.edges.length} adj."
# 
# puts "**** [Weighted Graph - Multigraph] *****"
# 
# puts "creating multigraph:"
# 
# multigraph = WeightedGraph.combine(mst, matching)
# 
# puts "  multigraph has #{multigraph.nodes.length} nodes"
# puts "  adjacency count: " + multigraph.edges.length.to_s
# puts "  degree distribution: " + multigraph.nodes.map { |node| multigraph.connected_to(node).length }.uniq.inspect

multigraph = WeightedGraph.new([[1, 2, 3, 4, 5], [1, 2, 3, 5, 4], [2, 1, 3, 5, 4], [2, 3, 1, 5, 4], [2, 3, 5, 1, 4], [2, 3, 5, 4, 1], [2, 3, 4, 5, 1], [2, 3, 4, 1, 5], [3, 2, 4, 1, 5], [3, 4, 2, 1, 5], [4, 3, 2, 1, 5], [4, 2, 3, 1, 5], [2, 4, 3, 1, 5], [2, 4, 3, 5, 1], [2, 4, 5, 3, 1], [2, 4, 5, 1, 3], [4, 2, 5, 1, 3], [4, 5, 2, 1, 3], [5, 4, 2, 1, 3], [5, 2, 4, 1, 3], [2, 5, 4, 1, 3], [2, 5, 4, 3, 1], [5, 2, 4, 3, 1], [5, 4, 2, 3, 1], [5, 4, 3, 2, 1], [5, 4, 3, 1, 2], [5, 4, 1, 3, 2], [5, 1, 4, 3, 2], [5, 1, 3, 4, 2], [5, 3, 1, 4, 2], [3, 5, 1, 4, 2], [3, 1, 5, 4, 2], [3, 1, 4, 5, 2], [3, 4, 1, 5, 2], [4, 3, 1, 5, 2], [4, 1, 3, 5, 2], [1, 4, 3, 5, 2], [1, 3, 4, 5, 2], [1, 3, 5, 4, 2], [1, 5, 3, 4, 2], [1, 5, 4, 3, 2], [1, 4, 5, 3, 2], [4, 1, 5, 3, 2], [4, 5, 1, 3, 2], [4, 5, 3, 1, 2], [4, 3, 5, 1, 2], [3, 4, 5, 1, 2], [3, 5, 4, 1, 2], [5, 3, 4, 1, 2], [5, 3, 4, 2, 1], [3, 5, 4, 2, 1], [3, 4, 5, 2, 1], [4, 3, 5, 2, 1], [4, 5, 3, 2, 1], [4, 5, 2, 3, 1], [4, 2, 5, 3, 1], [4, 2, 3, 5, 1], [4, 3, 2, 5, 1], [3, 4, 2, 5, 1], [3, 2, 4, 5, 1], [3, 2, 5, 4, 1], [3, 5, 2, 4, 1], [5, 3, 2, 4, 1], [5, 2, 3, 4, 1], [2, 5, 3, 4, 1], [2, 5, 3, 1, 4], [5, 2, 3, 1, 4], [5, 3, 2, 1, 4], [3, 5, 2, 1, 4], [3, 2, 5, 1, 4], [3, 2, 1, 5, 4], [3, 1, 2, 5, 4], [1, 3, 2, 5, 4], [1, 3, 5, 2, 4], [3, 1, 5, 2, 4], [3, 5, 1, 2, 4], [5, 3, 1, 2, 4], [5, 1, 3, 2, 4], [1, 5, 3, 2, 4], [1, 5, 2, 3, 4], [5, 1, 2, 3, 4], [5, 2, 1, 3, 4], [2, 5, 1, 3, 4], [2, 1, 5, 3, 4], [1, 2, 5, 3, 4], [1, 2, 5, 4, 3], [2, 1, 5, 4, 3], [2, 5, 1, 4, 3], [5, 2, 1, 4, 3], [5, 1, 2, 4, 3], [1, 5, 2, 4, 3], [1, 5, 4, 2, 3], [5, 1, 4, 2, 3], [5, 4, 1, 2, 3], [4, 5, 1, 2, 3], [4, 1, 5, 2, 3], [1, 4, 5, 2, 3], [1, 4, 2, 5, 3], [4, 1, 2, 5, 3], [4, 2, 1, 5, 3], [2, 4, 1, 5, 3], [2, 1, 4, 5, 3], [1, 2, 4, 5, 3], [1, 2, 4, 3, 5], [2, 1, 4, 3, 5], [2, 4, 1, 3, 5], [4, 2, 1, 3, 5], [4, 1, 2, 3, 5], [1, 4, 2, 3, 5], [1, 4, 3, 2, 5], [4, 1, 3, 2, 5], [4, 3, 1, 2, 5], [3, 4, 1, 2, 5], [3, 1, 4, 2, 5], [1, 3, 4, 2, 5], [1, 3, 2, 4, 5], [3, 1, 2, 4, 5], [3, 2, 1, 4, 5], [2, 3, 1, 4, 5], [2, 1, 3, 4, 5]], [[[1, 2, 3, 4, 5], 0.5, [1, 2, 3, 5, 4]], [[1, 2, 3, 5, 4], 0.5, [2, 1, 3, 5, 4]], [[2, 1, 3, 5, 4], 0.5, [2, 3, 1, 5, 4]], [[2, 3, 1, 5, 4], 0.5, [2, 3, 5, 1, 4]], [[2, 3, 5, 1, 4], 0.5, [2, 3, 5, 4, 1]], [[2, 3, 4, 5, 1], 0.5, [2, 3, 5, 4, 1]], [[2, 3, 4, 1, 5], 0.5, [2, 3, 4, 5, 1]], [[2, 3, 4, 1, 5], 0.5, [3, 2, 4, 1, 5]], [[3, 2, 4, 1, 5], 0.5, [3, 4, 2, 1, 5]], [[3, 4, 2, 1, 5], 0.5, [4, 3, 2, 1, 5]], [[4, 2, 3, 1, 5], 0.5, [4, 3, 2, 1, 5]], [[2, 3, 4, 1, 5], 0.5, [2, 4, 3, 1, 5]], [[2, 4, 3, 1, 5], 0.5, [2, 4, 3, 5, 1]], [[2, 4, 3, 5, 1], 0.5, [2, 4, 5, 3, 1]], [[2, 4, 5, 1, 3], 0.5, [2, 4, 5, 3, 1]], [[2, 4, 5, 1, 3], 0.5, [4, 2, 5, 1, 3]], [[4, 2, 5, 1, 3], 0.5, [4, 5, 2, 1, 3]], [[4, 5, 2, 1, 3], 0.5, [5, 4, 2, 1, 3]], [[5, 2, 4, 1, 3], 0.5, [5, 4, 2, 1, 3]], [[2, 4, 5, 1, 3], 0.5, [2, 5, 4, 1, 3]], [[2, 5, 4, 1, 3], 0.5, [2, 5, 4, 3, 1]], [[5, 2, 4, 1, 3], 0.5, [5, 2, 4, 3, 1]], [[5, 4, 2, 1, 3], 0.5, [5, 4, 2, 3, 1]], [[5, 4, 2, 3, 1], 0.5, [5, 4, 3, 2, 1]], [[5, 4, 3, 1, 2], 0.5, [5, 4, 3, 2, 1]], [[5, 4, 1, 3, 2], 0.5, [5, 4, 3, 1, 2]], [[5, 1, 4, 3, 2], 0.5, [5, 4, 1, 3, 2]], [[5, 1, 3, 4, 2], 0.5, [5, 1, 4, 3, 2]], [[5, 1, 3, 4, 2], 0.5, [5, 3, 1, 4, 2]], [[3, 5, 1, 4, 2], 0.5, [5, 3, 1, 4, 2]], [[3, 1, 5, 4, 2], 0.5, [3, 5, 1, 4, 2]], [[3, 1, 4, 5, 2], 0.5, [3, 1, 5, 4, 2]], [[3, 1, 4, 5, 2], 0.5, [3, 4, 1, 5, 2]], [[3, 4, 1, 5, 2], 0.5, [4, 3, 1, 5, 2]], [[4, 1, 3, 5, 2], 0.5, [4, 3, 1, 5, 2]], [[1, 4, 3, 5, 2], 0.5, [4, 1, 3, 5, 2]], [[1, 3, 4, 5, 2], 0.5, [1, 4, 3, 5, 2]], [[1, 3, 4, 5, 2], 0.5, [1, 3, 5, 4, 2]], [[1, 3, 5, 4, 2], 0.5, [1, 5, 3, 4, 2]], [[1, 5, 3, 4, 2], 0.5, [1, 5, 4, 3, 2]], [[1, 4, 3, 5, 2], 0.5, [1, 4, 5, 3, 2]], [[4, 1, 3, 5, 2], 0.5, [4, 1, 5, 3, 2]], [[4, 1, 5, 3, 2], 0.5, [4, 5, 1, 3, 2]], [[4, 5, 1, 3, 2], 0.5, [4, 5, 3, 1, 2]], [[4, 3, 1, 5, 2], 0.5, [4, 3, 5, 1, 2]], [[3, 4, 1, 5, 2], 0.5, [3, 4, 5, 1, 2]], [[3, 5, 1, 4, 2], 0.5, [3, 5, 4, 1, 2]], [[5, 3, 1, 4, 2], 0.5, [5, 3, 4, 1, 2]], [[5, 3, 4, 1, 2], 0.5, [5, 3, 4, 2, 1]], [[3, 5, 4, 1, 2], 0.5, [3, 5, 4, 2, 1]], [[3, 4, 5, 1, 2], 0.5, [3, 4, 5, 2, 1]], [[4, 3, 5, 1, 2], 0.5, [4, 3, 5, 2, 1]], [[4, 5, 3, 1, 2], 0.5, [4, 5, 3, 2, 1]], [[4, 5, 2, 3, 1], 0.5, [4, 5, 3, 2, 1]], [[4, 2, 5, 1, 3], 0.5, [4, 2, 5, 3, 1]], [[4, 2, 3, 1, 5], 0.5, [4, 2, 3, 5, 1]], [[4, 3, 2, 1, 5], 0.5, [4, 3, 2, 5, 1]], [[3, 4, 2, 1, 5], 0.5, [3, 4, 2, 5, 1]], [[3, 2, 4, 1, 5], 0.5, [3, 2, 4, 5, 1]], [[3, 2, 4, 5, 1], 0.5, [3, 2, 5, 4, 1]], [[3, 5, 2, 4, 1], 0.5, [3, 5, 4, 2, 1]], [[5, 3, 2, 4, 1], 0.5, [5, 3, 4, 2, 1]], [[5, 2, 3, 4, 1], 0.5, [5, 2, 4, 3, 1]], [[2, 5, 3, 4, 1], 0.5, [2, 5, 4, 3, 1]], [[2, 5, 3, 1, 4], 0.5, [2, 5, 3, 4, 1]], [[5, 2, 3, 1, 4], 0.5, [5, 2, 3, 4, 1]], [[5, 3, 2, 1, 4], 0.5, [5, 3, 2, 4, 1]], [[3, 5, 2, 1, 4], 0.5, [3, 5, 2, 4, 1]], [[3, 2, 5, 1, 4], 0.5, [3, 2, 5, 4, 1]], [[3, 2, 1, 5, 4], 0.5, [3, 2, 5, 1, 4]], [[3, 1, 2, 5, 4], 0.5, [3, 2, 1, 5, 4]], [[1, 2, 3, 5, 4], 0.5, [1, 3, 2, 5, 4]], [[1, 3, 5, 2, 4], 0.5, [1, 3, 5, 4, 2]], [[3, 1, 2, 5, 4], 0.5, [3, 1, 5, 2, 4]], [[3, 5, 1, 2, 4], 0.5, [3, 5, 2, 1, 4]], [[5, 3, 1, 2, 4], 0.5, [5, 3, 2, 1, 4]], [[5, 1, 3, 2, 4], 0.5, [5, 1, 3, 4, 2]], [[1, 5, 3, 2, 4], 0.5, [1, 5, 3, 4, 2]], [[1, 5, 2, 3, 4], 0.5, [1, 5, 3, 2, 4]], [[5, 1, 2, 3, 4], 0.5, [5, 1, 3, 2, 4]], [[5, 2, 1, 3, 4], 0.5, [5, 2, 3, 1, 4]], [[2, 5, 1, 3, 4], 0.5, [2, 5, 3, 1, 4]], [[2, 1, 3, 5, 4], 0.5, [2, 1, 5, 3, 4]], [[1, 2, 3, 5, 4], 0.5, [1, 2, 5, 3, 4]], [[1, 2, 5, 3, 4], 0.5, [1, 2, 5, 4, 3]], [[2, 1, 5, 3, 4], 0.5, [2, 1, 5, 4, 3]], [[2, 5, 1, 3, 4], 0.5, [2, 5, 1, 4, 3]], [[5, 2, 1, 3, 4], 0.5, [5, 2, 1, 4, 3]], [[5, 1, 2, 3, 4], 0.5, [5, 1, 2, 4, 3]], [[1, 5, 2, 3, 4], 0.5, [1, 5, 2, 4, 3]], [[1, 5, 4, 2, 3], 0.5, [1, 5, 4, 3, 2]], [[5, 1, 2, 4, 3], 0.5, [5, 1, 4, 2, 3]], [[5, 4, 1, 2, 3], 0.5, [5, 4, 1, 3, 2]], [[4, 5, 1, 2, 3], 0.5, [4, 5, 1, 3, 2]], [[4, 1, 5, 2, 3], 0.5, [4, 1, 5, 3, 2]], [[1, 4, 5, 2, 3], 0.5, [1, 4, 5, 3, 2]], [[1, 4, 2, 5, 3], 0.5, [1, 4, 5, 2, 3]], [[4, 1, 2, 5, 3], 0.5, [4, 1, 5, 2, 3]], [[4, 2, 1, 5, 3], 0.5, [4, 2, 5, 1, 3]], [[2, 4, 1, 5, 3], 0.5, [2, 4, 5, 1, 3]], [[2, 1, 4, 5, 3], 0.5, [2, 1, 5, 4, 3]], [[1, 2, 4, 5, 3], 0.5, [1, 2, 5, 4, 3]], [[1, 2, 4, 3, 5], 0.5, [1, 2, 4, 5, 3]], [[2, 1, 4, 3, 5], 0.5, [2, 1, 4, 5, 3]], [[2, 4, 1, 3, 5], 0.5, [2, 4, 1, 5, 3]], [[4, 2, 1, 3, 5], 0.5, [4, 2, 1, 5, 3]], [[4, 1, 2, 3, 5], 0.5, [4, 1, 2, 5, 3]], [[1, 4, 2, 3, 5], 0.5, [1, 4, 2, 5, 3]], [[1, 4, 3, 2, 5], 0.5, [1, 4, 3, 5, 2]], [[4, 1, 2, 3, 5], 0.5, [4, 1, 3, 2, 5]], [[4, 3, 1, 2, 5], 0.5, [4, 3, 2, 1, 5]], [[3, 4, 1, 2, 5], 0.5, [3, 4, 2, 1, 5]], [[3, 1, 4, 2, 5], 0.5, [3, 1, 4, 5, 2]], [[1, 3, 4, 2, 5], 0.5, [1, 3, 4, 5, 2]], [[1, 3, 2, 4, 5], 0.5, [1, 3, 2, 5, 4]], [[3, 1, 2, 4, 5], 0.5, [3, 1, 4, 2, 5]], [[3, 2, 1, 4, 5], 0.5, [3, 2, 1, 5, 4]], [[2, 3, 1, 4, 5], 0.5, [2, 3, 1, 5, 4]], [[2, 1, 3, 4, 5], 0.5, [2, 1, 4, 3, 5]], [[1, 2, 3, 4, 5], 0.5, [2, 1, 3, 4, 5]], [[2, 1, 3, 5, 4], 0.5, [2, 3, 1, 5, 4]], [[2, 3, 4, 1, 5], 0.5, [3, 2, 4, 1, 5]], [[5, 4, 1, 3, 2], 0.5, [5, 4, 2, 1, 3]], [[5, 1, 3, 4, 2], 0.5, [5, 1, 4, 2, 3]], [[3, 4, 1, 5, 2], 0.5, [5, 3, 1, 4, 2]], [[3, 1, 4, 5, 2], 0.5, [3, 5, 1, 4, 2]], [[1, 5, 3, 4, 2], 0.5, [4, 3, 1, 5, 2]], [[1, 3, 4, 5, 2], 0.5, [4, 1, 3, 5, 2]], [[1, 3, 5, 4, 2], 0.5, [4, 1, 5, 3, 2]], [[3, 4, 5, 2, 1], 0.5, [4, 5, 1, 3, 2]], [[3, 5, 1, 2, 4], 0.5, [4, 3, 5, 2, 1]], [[4, 2, 3, 5, 1], 0.5, [4, 5, 2, 3, 1]], [[2, 5, 1, 4, 3], 0.5, [4, 2, 5, 3, 1]], [[3, 1, 5, 2, 4], 0.5, [4, 3, 2, 5, 1]], [[1, 5, 4, 2, 3], 0.5, [3, 4, 2, 5, 1]], [[1, 3, 5, 2, 4], 0.5, [3, 2, 1, 5, 4]], [[5, 3, 1, 2, 4], 0.5, [5, 4, 1, 2, 3]], [[1, 5, 2, 4, 3], 0.5, [5, 2, 1, 4, 3]], [[1, 2, 4, 3, 5], 0.5, [4, 5, 1, 2, 3]], [[2, 4, 1, 3, 5], 0.5, [4, 1, 3, 2, 5]], [[1, 4, 2, 3, 5], 0.5, [4, 2, 1, 3, 5]], [[1, 4, 3, 2, 5], 0.5, [4, 3, 1, 2, 5]], [[1, 3, 2, 4, 5], 0.5, [3, 4, 1, 2, 5]], [[1, 3, 4, 2, 5], 0.5, [3, 1, 2, 4, 5]], [[2, 3, 1, 4, 5], 0.5, [3, 2, 1, 4, 5]]])

# puts multigraph.nodes.inspect
# puts multigraph.edges.inspect

eulerian_circuit = CircuitFinder.new(multigraph).seek!

puts eulerian_circuit.uniq.sort == multigraph.nodes.sort
puts "#{eulerian_circuit.length - 1}, #{multigraph.edges.length}"

puts multigraph.edges_for([1, 5, 3, 4, 2]).inspect
puts multigraph.edges.inject({}) {|hash, edge| hash[edge[1]] ||= 0; hash[edge[1]] += 1; hash }.inspect

puts multigraph.edges.inject({}) {|hash, edge| result = ExtentChecker.new([edge[0], edge[2]]).check; hash[result] ||= 0; hash[result] += 1; hash }.inspect

puts "************************"