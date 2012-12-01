class CircuitFinder
  
  attr_accessor :graph
  attr_accessor :backup_graph
  
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
    self.backup_graph = graph
    self.graph = graph.clone
  end
  
  def seek!
    
    # puts backup_graph.edges_for([3,4,1,2,5]).inspect
    # 1/0
    
    @tour = []
    @touched_edges = []
    @call_count = 0
  
    @touched_edges = []
      
    seek_from(graph.nodes.first, @tour)
    # puts "missed: #{backup_graph.edges.length} #{@touched_edges.length}"
    # puts "missed: #{backup_graph.edges.uniq.length} #{@touched_edges.uniq.length}"
        
    puts "checking connections..."
    @tour.each_with_index do |v, i|
      index = (i + 1) % @tour.length
      if !backup_graph.connected?(v, @tour[index])
        puts "#{i} FAIL: #{v} <-/-> #{@tour[index]}, #{index}, #{@tour.length}"
      end
    end
    
    return @tour
  end
  
  private  
    
  def seek_from(node, path)
    puts "seek called [#{path.length}][#{node.join}] for #{@call_count += 1} [graph.edges.length = #{graph.edges.length}]"
    
    next_nodes = graph.connected_to(path.last)
    
    if next_nodes.any?
      count_map = graph.edges_for(node).inject({}) do |hash, edge|
        hash[edge] ||= 0
        hash[edge] += 1
        hash 
      end
          
      edge, count = count_map.first
      other_node = edge[0] == node ? edge[2] : edge[0]
          
      graph.drop_edge(edge)
          
      if count == 2
        path.push(other_node)
        path = seek_from(node, path)
      elsif count == 1
        path = seek_from(other_node, path)
      else
        raise "very multigraph - unsupported!"
      end
          
    else
      puts "extruding from #{node.join}... [#{path.length}]"
      
      # str = path.first == path.last ? '1]*' : '1]'
      # puts str, path.map(&:join).join('<->')
      
      path.pop
      
      # puts '2]', path.map(&:join).join('<->')
      
      path = extrude_path(path)
      
      # puts '3]', path.map(&:join).join('<->')
    end
        
    path
  end
  
  def extrude_path(path)    
    path.each_with_index do |node, index|
      if graph.edges_for(node).length > 0
        path.insert(index, *seek_from(node, []))
      end
    end

    path
  end
  
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
  # def seek_from(node)
  #      puts "seek called for #{@call_count += 1} [graph.edges.length = #{graph.edges.length}]"        
  #      
  #      if graph.edges.length == 5
  #        puts "start = #{@tour.first}"
  #        puts "node = #{node}"
  #        puts graph.edges.inspect
  #      end
  #      
  #      
  #      graph.edges.each_with_index do |edge, index|  
  #        if edge[0] == node
  #          graph.edges.delete_at(index)
  #          seek_from(edge[2])
  #        elsif edge[2] == node
  #          graph.edges.delete_at(index)
  #          seek_from(edge[0])        
  #        end
  #      end
  #      
  #      @tour.push(node)
  #    end
  
  # def seek_from(node)
  #     puts "seek called [#{graph.nodes.index(node)}] for #{@call_count += 1} [graph.edges.length = #{graph.edges.length}]"
  #        
  #     if graph.edges.length == 5
  #       puts "start = #{@tour.first}"
  #       puts "node = #{node}"
  #       puts graph.edges.inspect
  #     end
  #        
  #     # suspect = [[[5, 1, 3, 2, 4], 0.5, [5, 1, 3, 4, 2]], [[5, 1, 2, 3, 4], 0.5, [5, 1, 3, 2, 4]], [[5, 1, 2, 3, 4], 0.5, [5, 1, 2, 4, 3]], [[5, 1, 2, 4, 3], 0.5, [5, 1, 4, 2, 3]], [[5, 1, 3, 4, 2], 0.5, [5, 1, 4, 2, 3]]]
  #        
  #     graph.edges.each do |edge|
  #       @touched_edges << edge  
  #       # puts "dropping #{edge.inspect}, count: #{graph.edges.count(edge)}"
  #       # # graph.drop_edge(edge)
  #       # puts "dropped #{edge.inspect}, count: #{graph.edges.count(edge)}"
  #          
  #       if edge[0] == node
  #              
  #         if graph.edges.count(edge) > 1
  #           puts "got multi -----#{edge[0]}-----------#{edge[2]}----------------"
  #           graph.drop_edge(edge)
  #           seek_from(node)
  #           @tour.push(edge[2]).push(node)
  #         else
  #           graph.drop_edge(edge)
  #           seek_from(edge[2])
  #         end
  #              
  #       elsif edge[2] == node
  #            
  #         if graph.edges.count(edge) > 1
  #           puts "got multi ----#{edge[0]}----------------#{edge[2]}------------"
  #           graph.drop_edge(edge)
  #           seek_from(node)
  #           @tour.push(edge[0]).push(node)          
  #         else
  #           graph.drop_edge(edge)
  #           seek_from(edge[0])
  #         end
  #       
  #       end
  #     
  # 
  #     end
  #        
  #     @tour.push(node)
  #   end
 
end