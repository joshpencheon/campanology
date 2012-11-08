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

require_relative 'lib/graph_builder'
require_relative 'lib/complete_graph'

require_relative 'lib/midi_creator'

extent = ExtentBuilder.new(6)

puts "**** [STATS] ****"

puts "#rows: #{extent.rows.length}"
puts "#rows (uniq): #{extent.rows.uniq.length}"

puts "valid extent: #{ExtentChecker.new(extent).check}"

puts "*****************"

# builder = GraphBuilder.new(4, [ 'x', '14', '12'])
# builder = GraphBuilder.new(7, [ 'x', '16', '12'])

# builder = GraphBuilder.new(6, [ 'x', '16', '12'])
builder = GraphBuilder.new(5, [ '345', '145', '125', '123'])

puts builder.nodes.length

puts "*****************"

complete = CompleteGraph.new(builder.nodes)

puts complete.adjacencies.map { |k, v| v.length }.inject(0, &:+)

puts CycleFinder.new(complete.nodes, complete.adjacencies).conditions_met?

puts "*****************"

finder = CycleFinder.from_graph_builder(builder)

puts finder.conditions_met?
results = finder.seek!

cycles = []
results.each do |starting_node, node_results|
  node_results ||= {}
  
  (node_results[:cycles] || []).each do |cycle|
    cycles << cycle
  end
end

puts "Cycle count: #{cycles.length}"
puts "Valid cycle count: #{cycles.select { |cycle| ExtentChecker.new(cycle).check }.length}"
puts "Unique cycle count: #{cycles.uniq.length}"

puts "*****************"

five_bells = ExtentBuilder.new(5)

pentatonic = ["Db4", "Eb4", "Gb4", "Ab4", "Bb4"]
tracks = []
pentatonic.length.times { |x| tracks << five_bells.tune(pentatonic.rotate(x)) }

MidiCreator.new(tracks).export!

puts "Extent MIDI outputted!"

puts "*****************"