class MatcherInterface
  
  CMD = File.join(File.dirname(__FILE__), '..', '..', 'blossom', 'blossom5')
  
  attr_accessor :graph
  
  def initialize(graph)
    self.graph = graph
  end
  
  def get_matching
    input_path = graph.to_dimacs('dimacs.graph')
    output_path = call_blossom(input_path, File.join(File.dirname(input_path), 'matching.graph'))
    edge_list = parse_blossom(output_path)
    
    graph.build_sub_graph(edge_list)
  end
  
  private
  
  def call_blossom(dimacs_path, output_path)
    %x[#{MatcherInterface::CMD} -e #{dimacs_path} -w #{output_path}]
    
    output_path
  end
  
  def parse_blossom(path)
    [].tap do |connections|
      File.open(path, 'r') do |file|
        lines = file.readlines
        node_count, edge_count = parse_line(lines.shift)
      
        lines.each { |line| connections << parse_line(line) }
      end      
    end
  end
  
  def parse_line(string)
    string.strip.split(/\s/).map(&:to_i)
  end
  
end