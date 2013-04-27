class MidiCreator
  
  TONE_MAP = [ "C(-1)", "Db(-1)", "D(-1)", "Eb(-1)", "E(-1)", "F(-1)", "Gb(-1)", 
    "G(-1)", "Ab(-1)", "A(-1)", "Bb(-1)", "B(-1)", "C0", "Db0", "D0", "Eb0", "E0",
    "F0", "Gb0", "G0", "Ab0", "A0", "Bb0", "B0", "C1", "Db1", "D1", "Eb1", "E1",
    "F1", "Gb1", "G1", "Ab1", "A1", "Bb1", "B1", "C2", "Db2", "D2", "Eb2", "E2",
    "F2", "Gb2", "G2", "Ab2", "A2", "Bb2", "B2", "C3", "Db3", "D3", "Eb3", "E3", "F3",
    "Gb3", "G3", "Ab3", "A3", "Bb3", "B3", "C4", "Db4", "D4", "Eb4", "E4", "F4", "Gb4",
    "G4", "Ab4", "A4", "Bb4", "B4", "C5", "Db5", "D5", "Eb5", "E5", "F5", "Gb5", "G5",
    "Ab5", "A5", "Bb5", "B5", "C6", "Db6", "D6", "Eb6", "E6", "F6", "Gb6", "G6", "Ab6",
    "A6", "Bb6", "B6", "C7", "Db7", "D7", "Eb7", "E7", "F7", "Gb7", "G7", "Ab7", "A7", 
    "Bb7", "B7", "C8", "Db8", "D8", "Eb8", "E8", "F8", "Gb8", "G8", "Ab8", "A8", "Bb8", 
    "B8", "C9", "Db9", "D9", "Eb9", "E9", "F9", "Gb9", "G9" ]
    
  attr_accessor :tracks
  
  def initialize(tracks)
    self.tracks = tracks
  end
  
  def export!
    path = File.join(File.dirname(__FILE__), "..", "extent.mid")
    
    File.open(path, 'w:binary') do |file|
      file.print(midi_bytes.map { |b| b.to_i(16) }.pack('C*'))
    end
  end
  
  private
  
  def encode(ring)
    MidiCreator::TONE_MAP.index(ring).to_s(16)
  end
   
  def midi_bytes
    bytes = []
    
    bytes << "4D" << "54" << "68" << "64" # "MThd"
    bytes << "00" << "00" << "00" << "06" # Size of rest of header
    bytes << "00" << "01" # MIDI subtype
        
    self.tracks.length.to_s(16).rjust(4, '0').scan(/../).each { |byte| bytes << byte }
    
    bytes << "00" << "80" # Play speed

    self.tracks.each_with_index do |track, track_index|
      bytes << "4D" << "54" << "72" << "6B" # "MTrk"
    
      # Total number of bytes in the track:
      #   (4 on, 4 off per ring, plus 8 for a pause after each round,
      #    plus 4 extra bytes to denote the end of the track)
      bytes += ((track.length * 8) + (track.flatten.length * 8) + 4).to_s(16).rjust(8, '0').scan(/../)
    
      n = track.first.length 
      track.flatten.each_with_index do |ring, index|
        bytes << "00" << "9#{track_index}" << encode(ring) << "60" # Note on
        bytes << "40" << "8#{track_index}" << encode(ring) << "60" # Note off
      
        # Add pause after each round:
        bytes += %W( 20 9#{track_index} 00 00 20 9#{track_index} 00 00 ) if index % n == n - 1
      end
    
      bytes << "00" << "FF" << "2F" << "00" # End of track
    end
    
    bytes
  end
    
end