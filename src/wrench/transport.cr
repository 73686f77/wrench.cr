class Transport
  enum Side : UInt8
    Client = 0_u8
    Remote = 1_u8
  end

  getter client : IO
  getter remote : IO
  getter callback : Proc(Int64, Int64, Nil)?
  getter heartbeat : Proc(Nil)?
  getter mutex : Mutex

  def initialize(@client, @remote : IO, @callback : Proc(Int64, Int64, Nil)? = nil, @heartbeat : Proc(Nil)? = nil)
    @mutex = Mutex.new :unchecked
  end

  def remote_tls_context=(value : OpenSSL::SSL::Context::Client)
    @remoteTlsContext = value
  end

  def remote_tls_context
    @remoteTlsContext
  end

  def remote_tls=(value : OpenSSL::SSL::Socket::Client)
    @remoteTls = value
  end

  def remote_tls
    @remoteTls
  end

  def client_tls_context=(value : OpenSSL::SSL::Context::Server)
    @clientTlsContext = value
  end

  def client_tls_context
    @clientTlsContext
  end

  def client_tls=(value : OpenSSL::SSL::Socket::Server)
    @clientTls = value
  end

  def client_tls
    @clientTls
  end

  def heartbeat_interval=(value : Time::Span)
    @heartbeatInterval = value
  end

  def heartbeat_interval
    @heartbeatInterval ||= 10_i32.seconds
  end

  private def uploaded_size=(value : Int64)
    @uploadedSize = value
  end

  def uploaded_size
    @uploadedSize
  end

  private def received_size=(value : Int64)
    @receivedSize = value
  end

  def received_size
    @receivedSize
  end

  private def latest_alive=(value : Time)
    @latestAlive = value
  end

  private def latest_alive
    @latestAlive
  end

  def alive_interval=(value : Time::Span)
    @aliveInterval = value
  end

  def alive_interval
    @aliveInterval || 1_i32.minutes
  end

  def extra_uploaded_size=(value : Int32 | Int64)
    @extraUploadedSize = value
  end

  def extra_uploaded_size
    @extraUploadedSize || 0_i32
  end

  def extra_received_size=(value : Int32 | Int64)
    @extraReceivedSize = value
  end

  def extra_received_size
    @extraReceivedSize || 0_i32
  end

  def side=(side : Side)
    @side = side
  end

  def side
    @side
  end

  def cleanup
    unless remote.closed?
      remote.close rescue nil
      remote_tls.try &.free
      remote_tls_context.try &.free
    end

    unless client.closed?
      client.close rescue nil
      client_tls.try &.free
      client_tls_context.try &.free
    end
  end

  def update_latest_alive
    @mutex.synchronize { @latestAlive = Time.local }
  end

  def perform
    update_latest_alive

    spawn do
      exception = nil
      count = 0_i64

      loop do
        size = begin
          IO.super_copy(client, remote) { update_latest_alive }
        rescue ex : IO::CopyException
          exception = ex.cause
          ex.count
        end

        size.try { |_size| count += _size }

        break unless _latest_alive = latest_alive
        break if alive_interval <= (Time.local - _latest_alive)

        break if received_size && exception
        break unless exception
        break if exception.is_a? IO::Error

        sleep 0.05_f32.seconds
      end

      self.uploaded_size = (count || 0_i64) + extra_uploaded_size
    end

    spawn do
      exception = nil
      count = 0_i64

      loop do
        size = begin
          IO.super_copy(remote, client) { update_latest_alive }
        rescue ex : IO::CopyException
          exception = ex.cause
          ex.count
        end

        size.try { |_size| count += _size }

        break unless _latest_alive = latest_alive
        break if alive_interval <= (Time.local - _latest_alive)

        break if uploaded_size && exception
        break unless exception
        break if exception.is_a? IO::Error

        sleep 0.05_f32.seconds
      end

      self.received_size = (count || 0_i64) + extra_received_size
    end

    spawn do
      loop do
        status = ->do
          case side
          when Side::Client
            uploaded_size || received_size
          else
            uploaded_size && received_size
          end
        end

        if status.call
          loop do
            _uploaded_size = uploaded_size
            _received_size = received_size

            if _uploaded_size && _received_size
              break callback.try &.call _uploaded_size, _received_size
            end

            sleep 0.05_f32.seconds
          end

          break
        end

        if _heartbeat = heartbeat
          _heartbeat.call rescue nil
          sleep heartbeat_interval.seconds
        else
          sleep 0.25_f32.seconds
        end
      end
    end
  end
end
