class HTTP::WebSocket::Protocol
  def io_close
    @io.close
  end

  def flush
    @io.flush
  end

  def closed?
    @io.closed?
  end

  def read_timeout=(value : Int | Float | Time::Span | Nil)
    _wrapped = @io
    _wrapped.read_timeout = value if value if _wrapped.responds_to? :read_timeout=
  end

  def write_timeout=(value : Int | Float | Time::Span | Nil)
    _wrapped = @io
    _wrapped.write_timeout = value if value if _wrapped.responds_to? :write_timeout=
  end

  def read_timeout
    _wrapped = @io
    _wrapped.read_timeout if _wrapped.responds_to? :read_timeout
  end

  def write_timeout
    _wrapped = @io
    _wrapped.write_timeout if _wrapped.responds_to? :write_timeout
  end

  def all_free
    _wrapped = @io

    _wrapped.all_free if _wrapped.responds_to? :all_free
  end
end
