class Transport
  getter client : IO
  getter remote : IO
  getter callback : Proc(UInt64, UInt64, Nil)?
  getter mutex : Mutex

  def initialize(@client, @remote : IO, @callback : Proc(UInt64, UInt64, Nil)? = nil)
    @mutex = Mutex.new :unchecked
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

  def extra_uploaded_size=(value : Int32)
    @extraUploadedSize = value
  end

  def extra_uploaded_size
    @extraUploadedSize || 0_i32
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

  def cleanup
    @mutex.synchronize do
      return if client.closed? && remote.closed?

      client.close rescue nil
      remote.close rescue nil
      client_tls.try &.free
      remote_tls.try &.free

      sleep 0.05_f32
    end
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

      self.uploaded_size = (count || 0_u64) + extra_uploaded_size
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
        break cleanup if uploaded_size || received_size

        sleep 1_i32.seconds
      end
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
