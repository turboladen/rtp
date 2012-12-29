module RTP
  module FFmpeg
    AVAudioServiceType = enum :main,
                              :effects,
                              :visually_impaired,
                              :hearing_impaired,
                              :dialogue,
                              :commentary,
                              :emergency,
                              :voice_over,
                              :karaoke,
                              :nb
  end
end