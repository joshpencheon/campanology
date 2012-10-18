require_relative 'test_helper'

describe CycleFinder do
  
  before(:each) do
    nodes = [1,2,3,4]
    adjacencies = Matrix[
      [0,0,1,1],
      [0,0,1,0],
      [1,1,0,1],
      [1,0,1,0]
    ]
    
    @finder = CycleFinder.new(nodes, adjacencies)
  end
  
  it "should have symmetric adjacency matrix" do
    @finder.adjacencies.symmetric?.must_equal true
  end
  
  it "should detect connections correctly" do
    @finder.send(:connected_to, 1).must_equal [3,4]
    @finder.send(:connected_to, 2).must_equal [3]
    @finder.send(:connected_to, 3).must_equal [1,2,4]
    @finder.send(:connected_to, 4).must_equal [1,3]
  end
  
end