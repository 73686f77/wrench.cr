class Log
  def initialize(@source : String = String.new, @backend : Backend? = IO::Backend.new, level : Severity = Severity::Info)
    @initial_level = level
  end

  def self.new(io : IO, without_progname : Bool? = false)
    new backend: IOBackend.new io, without_progname
  end

  {% for method, severity in {debug: Severity::Debug, trace: Severity::Trace,
                              info: Severity::Info, warn: Severity::Warn, notice: Severity::Notice,
                              error: Severity::Error, fatal: Severity::Fatal} %}

    # Logs a message if the logger's current severity is lower or equal to `{{severity}}`.
    def {{method.id}}(message : String, exception : Exception? = nil)
      return unless backend = @backend
      severity = Severity.new {{severity}}
      return unless level <= severity
      entry = Entry.new @source, severity, message, exception
      backend.write entry
    end
  {% end %}
end
