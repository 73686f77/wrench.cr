class Transport
  getter client : IO
  getter remote : IO
  getter callback : Proc(UInt64, UInt64, Nil)?

  def initialize(@client, @remote : IO, @callback : Proc(UInt64, UInt64, Nil)? = nil)
  end

  private def uploaded_size=(value : UInt64)
    @uploadedSize = value
  end

  private def uploaded_size
    @uploadedSize
  end

  private def received_size=(value : UInt64)
    @receivedSize = value
  end

  private def received_size
    @receivedSize
  end

  private def last_alive=(value : Time)
    @lastAlive = value
  end

  private def last_alive
    @lastAlive
  end

  def alive_interval=(value : Time::Span)
    @aliveInterval = value
  end

  def alive_interval
    @aliveInterval || 1_i32.minutes
  end

  def remote_tls=(value : OpenSSL::SSL::Socket::Client)
    @remoteTls = value
  end

  def remote_tls
    @remoteTls
  end

  def client_tls=(value : OpenSSL::SSL::Socket::Server)
    @clientTls = value
  end

  def client_tls
    @clientTls
  end

  def perform
    self.last_alive = Time.local

    spawn do
      exception = nil
      count = 0_u64

      loop do
        size = begin
          IO.super_copy(client, remote) { self.last_alive = Time.local }
        rescue ex : IO::CopyException
          exception = ex.cause
          ex.count
        end

        size.try { |_size| count += _size }

        break unless _last_alive = last_alive
        break if (Time.local - _last_alive) > alive_interval
        break if exception.nil?
        break unless exception.is_a? IO::TimeoutError

        sleep 0.05_f32.seconds
      end

      self.uploaded_size = count || 0_u64
    end

    spawn do
      exception = nil
      count = 0_u64

      loop do
        size = begin
          IO.super_copy(remote, client) { self.last_alive = Time.local }
        rescue ex : IO::CopyException
          exception = ex.cause
          ex.count
        end

        size.try { |_size| count += _size }

        break unless _last_alive = last_alive
        break if (Time.local - _last_alive) > alive_interval
        break if exception.nil?
        break unless exception.is_a? IO::TimeoutError

        sleep 0.05_f32.seconds
      end

      self.received_size = count || 0_u64
    end

    spawn do
      loop do
        if uploaded_size || received_size
          client.close rescue nil
          break remote.close rescue nil
        end

        sleep 1_i32.seconds
      end
    ensure
      client_tls.try &.free
      remote_tls.try &.free
    end

    spawn do
      loop do
        _uploaded_size = uploaded_size
        _received_size = received_size

        if _uploaded_size && _received_size
          break callback.try &.call _uploaded_size, _received_size
        end

        sleep 1_i32.seconds
      end
    end
  end
end
