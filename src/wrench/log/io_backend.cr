class Log::IOBackend
  def self.new(io : IO, without_progname : Bool) : IOBackend
    backend = new io
    backend.progname = String.new if without_progname

    backend
  end
end
