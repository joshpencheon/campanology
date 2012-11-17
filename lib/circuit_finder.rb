class CircuitFinder
  
  attr_accessor :graph
  attr_accessor :backup_edges
  attr_accessor :removed_edges
  
  def initialize(graph)
    puts "CF init with #{graph.nodes.length} nodes and #{graph.edges.length} edges"

    # odd_nodes = graph.nodes.select { |node| graph.edges_for(node).length % 2 == 1 }
    # 
    # if odd_nodes.any?
    #   odd_nodes.each do |node|
    #     puts node.inspect
    #     puts graph.edges_for(node).inspect
    #   end
    #   raise ArgumentError, "Not all vertices have even degree!"
    # end

    self.graph = graph
    self.backup_edges = graph.edges
    self.removed_edges = []
        
    @call_count = 0
  end
  
  def seek!
    @tour = []
    seek_from(graph.nodes.first)
    graph.edges = backup_edges
    puts "seek_from called #{@call_count} times"
    return @tour
  end
  
  private  
    
   
  # === The Algorithm ===
  #
  #   'tour' is a stack
  #   
  #   find_tour(u):
  #     for each edge e=(u,v) in E:
  #       remove e from E
  #       find_tour(v)
  #     prepend u to tour
  #   
  #   to find the tour, clear stack 'tour' and call find_tour(u),
  #   where u is any vertex with a non-zero degree.
  #    
  def seek_from(node)
    @call_count += 1
    
    edges_for_node = graph.edges_for(node)
    puts "[#{@call_count}] got #{edges_for_node.length} edges for node"
    puts "graph has #{edge_count = graph.edges.length} edges in total"

    edges_for_node.each_with_index do |edge, index|
      nth_occurance = (edges_for_node[0, index-1] || [edge]).count(edge)
      count = 0
      
      new_edges = []
      graph.edges.each_with_index do |edge_i, i|
        if edge_i != edge
          new_edges << edge_i
        else
          count += 1
          new_edges << edge_i unless count == nth_occurance
          puts "#{count} == #{nth_occurance} ?"
        end
      end
            
      graph.edges = new_edges
      
      if new_edges.any?
        other_node = [edge[0], edge[2]].reject { |n| n == node }.first
        seek_from(other_node)
      end
    end
    
    puts "#[#{graph.nodes.index(node)}]: adding #{node} to tour..., when #edges = #{edge_count}"
    @tour.push(node)
  end
  
end