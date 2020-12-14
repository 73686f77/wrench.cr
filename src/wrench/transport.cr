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

  def maximum_closed_cycle_times=(value : Int32)
    @maximumClosedCycleTimes = value
  end

  def maximum_closed_cycle_times
    @maximumClosedCycleTimes || 10_i32
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

  def heartbeat_interval=(value : Time::Span)
    @heartbeatInterval = value
  end

  def heartbeat_interval
    @heartbeatInterval ||= 10_i32.seconds
  end

  private def uploaded_size=(value : Int64)
    @uploadedSize = value
  end

  private def uploaded_size
    @uploadedSize
  end

  private def received_size=(value : Int64)
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
    @mutex.synchronize do
      return if client.closed? && remote.closed?

      remote.close rescue nil
      client.close rescue nil

      client_tls.try &.free
      remote_tls.try &.free
    end
  end

  def update_last_alive
    @mutex.synchronize { @lastAlive = Time.local }
  end

  def perform
    update_last_alive

    spawn do
      exception = nil
      count = 0_i64

      loop do
        size = begin
          IO.super_copy(client, remote) { update_last_alive }
        rescue ex : IO::CopyException
          exception = ex.cause
          ex.count
        end

        size.try { |_size| count += _size }

        break unless _last_alive = last_alive
        break if (Time.local - _last_alive) > alive_interval

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
          IO.super_copy(remote, client) { update_last_alive }
        rescue ex : IO::CopyException
          exception = ex.cause
          ex.count
        end

        size.try { |_size| count += _size }

        break unless _last_alive = last_alive
        break if (Time.local - _last_alive) > alive_interval

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
          cleanup

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
          error = false
          _heartbeat.call rescue error = true
          next if error

          sleep heartbeat_interval.seconds
        else
          sleep 0.05_f32.seconds
        end
      end
    end
  end
end
