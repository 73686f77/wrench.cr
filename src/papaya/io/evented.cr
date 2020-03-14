module IO::Evented
  # Returns the time to wait when reading before raising an `IO::Timeout`.
  def client_read_timeout : Time::Span?
    @client_read_timeout
  end

  # Sets the time to wait when reading before raising an `IO::Timeout`.
  def client_read_timeout=(timeout : Time::Span?) : ::Time::Span?
    @client_read_timeout = timeout
  end

  # Sets the number of seconds to wait when reading before raising an `IO::Timeout`.
  def client_read_timeout=(read_timeout : Number) : ::Time::Span?
    self.client_read_timeout = read_timeout.seconds
    client_read_timeout
  end

  # Returns the time to wait when writing before raising an `IO::Timeout`.
  def client_write_timeout : Time::Span?
    @client_write_timeout
  end

  # Sets the time to wait when writing before raising an `IO::Timeout`.
  def client_write_timeout=(timeout : Time::Span?) : ::Time::Span?
    @client_write_timeout = timeout
  end

  # Sets the number of seconds to wait when writing before raising an `IO::Timeout`.
  def client_write_timeout=(write_timeout : Number) : ::Time::Span?
    self.client_write_timeout = write_timeout.seconds
    client_write_timeout
  end
end
