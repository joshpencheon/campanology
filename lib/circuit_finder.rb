class CircuitFinder
  
  attr_accessor :graph
  attr_accessor :backup_edges
  
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

    self.graph = graph.clone
  end
  
  def seek!
    @tour = []
    @call_count = 0
    seek_from(graph.nodes.first)
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
    puts "seek called for #{@call_count += 1} [graph.edges.length = #{graph.edges.length}]"        
    
    if graph.edges.length == 5
      puts "start = #{@tour.first}"
      puts "node = #{node}"
      puts graph.edges.inspect
    end
    
    
    graph.edges.each_with_index do |edge, index|  
      if edge[0] == node
        graph.edges.delete_at(index)
        seek_from(edge[2])
      elsif edge[2] == node
        graph.edges.delete_at(index)
        seek_from(edge[0])        
      end
    end
    
    @tour.push(node)
  end
  
end