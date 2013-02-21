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
require_relative 'lib/node'
require_relative 'lib/weighted_graph'

require_relative 'lib/matcher_interface'

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
builder = GraphBuilder.new(5, [ '345', '145', '125', '123'])
# builder = GraphBuilder.new(6, [ 'x', '16', '12'])
# builder = GraphBuilder.new(6, ['3456', '1456', '1256', '1236', '1234', '12'])
# builder = GraphBuilder.new(7, ['34567', '14567', '12567', '12367', '12347', '12345'])
# builder = GraphBuilder.new(7, ['34567', '14567', '12567', '12367', '12347', '12345'])

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

bell_count = (builder.nodes.first || []).length
puts "On #{bell_count} bells, expect #{ChangeFinder.count_for(bell_count)} valid changes..."
ChangeFinder.new(bell_count).valid_changes_in_notation.each_with_index { |change, index| puts "  #{index+1}:  #{change.inspect}" }

puts "**** [Weighted Graph - Prim's] ****"

puts "Weighting original graph... [CAUTION BROKEN]"

puts "  init nodes..."
weighted_graph = WeightedGraph.new(builder.nodes.map { |arr| Node.new(arr.join) })

puts "  initial connections... [using #{builder.changes.length} changes]"
# Connect up vertices with used changes
builder.adjacencies.keys.each_with_index do |node, index|
  (builder.adjacencies[node] - builder.adjacencies.keys[0, index]).each do |other_node|
    weighted_graph.connect!(weighted_graph.send(:get_node, node.join), weighted_graph.send(:get_node,other_node.join), 0.5)
  end
end

puts "  rest of connections..."
weighted_graph.nodes.each_with_index do |node, index|
  weighted_graph.nodes[index+1, weighted_graph.nodes.length].each do |other_node|
    if !node.connected?(other_node)
      if ExtentChecker.new([node, other_node]).check
        weighted_graph.connect!(node, other_node, 0.51)
      else
        weighted_graph.connect!(node, other_node, 1)
      end
    end
  end
end

puts "  - has #{weighted_graph.nodes.length} nodes"
puts "  - has #{weighted_graph.edges.length} edges"
puts "  - weight distribution: #{weighted_graph.edges.inject({}) {|h, e| h[e[1]] ||= 0; h[e[1]] += 1; h }.inspect}"
puts "  - expected: dist[0.5] + dist[0.51] = twice number of nodes, at proportion of used-changes:available-changes."

puts "Finding MST using Prim's algorithm..."

mst = weighted_graph.minimum_spanning_tree([0.5, 0.51, 1])

puts "  MST has #{mst.nodes.length} nodes"
puts "  adjacency count: " + mst.edges.length.to_s
puts "  distinct weights: #{mst.edges.map {|e| e[1] }.uniq.inspect}"
puts "  degree distribution: " + mst.nodes.map(&:degree).uniq.inspect
puts "  total degree: " + mst.nodes.map(&:degree).inject(0, &:+).to_s

puts "**** [Weighted Graph - DIMACS] *****"

puts "Exporting weighted graph to file, using DIMAC formatting..."
weighted_graph.to_dimacs("weighted_builder")
puts "...done!"

puts "**** [Weighted Graph - BLOSSOMING] *****"

odd_nodes = []
mst.nodes.each { |node| odd_nodes << weighted_graph.get_node(node) if node.degree % 2 == 1 }
odd_nodes.each { |node| node.keep_connections(odd_nodes) }

matching_target = WeightedGraph.new(odd_nodes)

puts "  matching_target has #{matching_target.nodes.length} nodes"
puts "  edges count: " + matching_target.edges.length.to_s

blossom_proxy = MatcherInterface.new(matching_target)

puts "blossoming..."
matching = blossom_proxy.get_matching
puts "  - got matching, with #{matching.nodes.length} nodes and #{matching.edges.length} adj."

puts "**** [Weighted Graph - Multigraph] *****"

puts "creating multigraph:"

# mst.nodes.each do |node|
#   puts "#{node.to_s} -> #{node.connections.map {|k, v| k.to_s + ' ' + v.inspect}}"
# end
# puts "...."
# matching.nodes.each do |node|
#   puts "#{node.to_s} -> #{node.connections.map {|k, v| k.to_s + ' ' + v.inspect}}"
# end

multigraph = WeightedGraph.combine(mst, matching)

puts "  multigraph has #{multigraph.nodes.length} nodes"
puts "  adjacency count: " + multigraph.edges.length.to_s
puts "  degree distribution: " + multigraph.nodes.map(&:degree).uniq.inspect
puts "  total degree: " + multigraph.nodes.map(&:degree).inject(0, &:+).to_s
puts "  distinct weights: #{multigraph.edges.map {|e| e[1] }.uniq.inspect}"

puts "**** [Weighted Graph - Eulerian Circuit] *****"

eulerian_circuit = CircuitFinder.new(multigraph).seek!

puts "multi total degree: " + multigraph.nodes.map(&:degree).inject(0, &:+).to_s
puts "  has #{multigraph.nodes.length} nodes"
puts "  has #{multigraph.nodes.map(&:degree).inject(0, &:+) / 2} edges"

puts "eulerian circuit:"
puts "  visits #{eulerian_circuit.nodes.length} nodes"

# multigraph.nodes.each do |node|
#   puts "#{node.to_s} -> #{node.connections.map {|k, v| k.to_s + ' ' + v.inspect}}"
# end

# lengths = []
# eulerian_circuit.each_with_index do |node, index|
#   if index > 0
#     multigraph.get_node(node).connections[multigraph.get_node(eulerian_circuit[index-1])].each { |d| lengths << d}
#   end
# end

# eulerian_circuit.nodes.each_with_index do |node, index|
#   if index > 0
#     other_node = eulerian_circuit[index-1] 
#     multigraph.get_node(node).distance_between(multigraph.get_node(other_node)).each do |dist|
#       if dist == 0.51 
#         
#       end
#     end
#   end
# end

puts "  degree distribution: " + eulerian_circuit.nodes.map(&:degree).uniq.inspect
puts "  distinct weights: #{eulerian_circuit.edges.map {|e| e[1] }.uniq.inspect}"
puts "************************"