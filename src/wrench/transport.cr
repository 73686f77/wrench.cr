class Transport
  getter client : IO
  getter remote : IO
  getter callback : Proc(UInt64, UInt64, Nil)?

  def initialize(@client, @remote : IO, @callback : Proc(UInt64, UInt64, Nil)? = nil)
  end

  def maximum_timed_out=(value : Int32)
    @maximumTimedOut = value
  end

  def maximum_timed_out
    @maximumTimedOut || 64_i32
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

  # I ’m going to make a long talk here, about why I did this (all_transport)
  # Some time ago, I found that if the client is writing data to Remote, if Remote is also reading at the same time, it will trigger the problem of read timeout, and vice versa.
  # So far, I still don't know if it is a bad implementation of Crystal (IO::Evented).
  # So I thought of this solution.
  # When the timeout is triggered, immediately check whether the other party (upload / receive) has completed the transmission, otherwise continue to loop IO.copy.
  # At the same time, in order to avoid the infinite loop problem, I added the maximum number of attempts.
  # This ensures that there is no disconnection when transferring data for a long time.
  # Taking a 30-second timeout as an example, 30 * maximum number of attempts (default: 64) = 1920 seconds

  def perform
    spawn do
      timed_out_counter = 0_u64
      exception = nil
      count = 0_u64

      loop do
        size = begin
          IO.copy client, remote, true
        rescue ex : IO::CopyException
          exception = ex.cause
          ex.count
        rescue
          nil
        end

        size.try { |_size| count += _size }
        break if maximum_timed_out <= timed_out_counter

        case exception
        when IO::TimeoutError
          timed_out_counter += 1_i32
          next sleep 0.05_f32.seconds unless received_size
        else
        end

        break
      end

      self.uploaded_size = count || 0_u64
    end

    spawn do
      timed_out_counter = 0_u64
      exception = nil
      count = 0_u64

      loop do
        size = begin
          IO.copy remote, client, true
        rescue ex : IO::CopyException
          exception = ex.cause
          ex.count
        rescue ex
          nil
        end

        size.try { |_size| count += _size }
        break if maximum_timed_out <= timed_out_counter

        case exception
        when IO::TimeoutError
          timed_out_counter += 1_i32
          next sleep 0.05_f32.seconds unless uploaded_size
        else
        end

        break
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
