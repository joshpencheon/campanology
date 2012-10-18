require_relative 'test_helper'

describe Matrix do
  
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
  
  it "should drop columns/rows correctly" do
    
    old_matrix = Matrix[ [1,0,1], [0,1,1], [1,1,1] ]
    new_matrix = Matrix[ [1,0], [0,1] ]
    
    Matrix.drop(old_matrix, [2]).must_equal new_matrix
    
  end
    
end