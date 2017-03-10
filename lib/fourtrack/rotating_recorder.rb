# Can be used the same as a Recorder, but it will output path
# as the format argument for `Time#strftime`
class Fourtrack::RotatingRecorder < Fourtrack::Recorder
  def initialize(output_pattern:, **options_for_recorder)
    @output_path_pattern = output_pattern
    first_file_path = Time.now.utc.strftime(@output_path_pattern)
    super(output_path: first_file_path, **options_for_recorder)
  end

  private

  def output_path
    Time.now.utc.strftime(@output_path_pattern)
  end
end
