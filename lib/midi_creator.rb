class MidiCreator
  
  attr_accessor :rows
  attr_accessor :note_map
  
  def initialize(rows, note_map = build_default_note_map)
    self.rows = rows
    self.note_map = note_map
  end
  
  def export(path)
    File.open(path, 'w') do |file|
      midi_bytes.each do |byte|
        file.print(byte.chr)
      end
    end
  end
  
  private
  
  def encode(ring)
    note_map[ring].to_s(16)
  end
  
  # Map 1..12 to the octave starting from middle C (c4).
  def build_default_note_map
    {}.tap do |map|
      (1..12).each { |tone| map[tone] = 59 + tone }
    end
  end
  
  def midi_bytes
    bytes = []
    
    bytes << "4D" << "54" << "68" << "64" # "MThd"
    bytes << "00" << "00" << "00" << "06" # Size of rest of header
    bytes << "00" << "01" # MIDI subtype
    bytes << "00" << "01" # Track count
    bytes << "00" << "80" # Play speed
    
    bytes << "4D" << "54" << "72" << "6B" # "MTrk"
    
    # Total number of bytes in the track:
    #   (4 on, 4 off per ring)
    bytes += (self.rows.flatten.length * 8).to_s(16).rjust(8, '0').scan(/../)
    
    self.rows.flatten.each do |ring|
      bytes << "7F" << "90" << encode(ring) << "60" # Note on
      bytes << "7F" << "80" << encode(ring) << "60" # Note off
    end
    
    bytes << "00" << "FF" << "2F" << "00" # End of track
  end
    
end