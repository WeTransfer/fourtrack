require 'spec_helper'
require 'tempfile'
require 'json'
require 'securerandom'

describe Fourtrack::RotatingRecorder do
  it 'cycles files every second' do
    Dir.mktmpdir do |dir_path|
      out_path = File.join(dir_path, 'log-%s.gz')
      replay_log = Fourtrack::RotatingRecorder.new(output_pattern: out_path, flush_after: 12)
      10.times do
        sleep 0.5
        123.times { replay_log << "Hello!\n" }
      end
      replay_log.flush!
      
      written_log_paths = Dir.glob(File.join(dir_path + '/log-*.gz'))
      expect(5..7).to cover(written_log_paths.length)
    end
  end
end
