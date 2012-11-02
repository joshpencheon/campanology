class Extent
  attr_accessor :rows
  
  def tune(tones)
    if rows.first.length != tones.length
      raise ArgumentError, "Tone mismatch: expected #{rows.first.length} tones, got #{tones.length}!"
    end
    
    self.rows.map do |row|
      row.map { |bell_number| tones[bell_number - 1] }
    end
  end
end