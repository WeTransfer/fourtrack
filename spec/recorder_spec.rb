require 'spec_helper'
require 'tempfile'
require 'json'
require 'securerandom'

describe Fourtrack::Recorder do
  it 'flushes the written entries when the containing PID exits' do
    out = Tempfile.new 'rl_test'
    pid = fork do
      replay_log = Fourtrack::Recorder.new(output_path: out.path, flush_after: 12)
      sleep 0.3
      3.times { replay_log << {hello: "Hi there stranger!"} }
    end
    Process.wait(pid)
    out.rewind
    lines = Zlib::GzipReader.new(out).readlines
    expect(lines.length).to eq(3)
  end
  
  it 'does not flush the records twice if the parent process forks off a child' do
    out = Tempfile.new 'rl_test'
    replay_log = Fourtrack::Recorder.new(output_path: out.path, flush_after: 512, logger: Logger.new($stderr))
    
    # Accumulate some records from master
    14.times { replay_log << JSON.dump({parent: SecureRandom.hex(23)}) }
    
    # Then fork off a child
    pid = fork do
      sleep 0.3
      16.times do
        replay_log << JSON.dump({child: SecureRandom.hex(23)})
      end
    end
    replay_log.flush! # Flush manually since in the master we do not exit - it is our rspec process
    Process.wait(pid)

    out.rewind
    
    lines = Fourtrack::Player.new(out).readlines
    expect(lines.length).to eq(30)
  end
end
