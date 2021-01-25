class Log
  def initialize(@source : String = String.new, @backend : Backend? = IO::Backend.new, level : Severity = Severity::Info)
    @initial_level = level
  end

  {% for method, severity in {trace: Severity::Trace, debug: Severity::Debug,
                              info: Severity::Info, notice: Severity::Notice,
                              warn: Severity::Warn, error: Severity::Error,
                              fatal: Severity::Fatal} %}
    # Logs a message if the logger's current severity is lower or equal to `{{severity}}`.

    def {{method.id}}(result : String | Entry, exception : Exception? = nil)
      return unless backend = @backend
      severity = Severity.new {{severity}}
      return unless level <= severity

      entry = case result
        when Entry
          result
        else
          dsl = Emitter.new @source, severity, exception
          dsl.emit result.to_s
        end

      backend.dispatch entry
    end
  {% end %}
end
