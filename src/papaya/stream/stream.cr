module Stream
  def self.chunk(io : IO, buffer_size : Int32 = 131072_i32, sync_close : Bool = false, &block : IO::Memory, Float64, Bool, Bool ->)
    buffer = IO::Memory.new buffer_size
    finished = false
    _chunk_size = 0_i32 ensure stream_size = 0_f64

    finished = true if io.closed?

    until finished
      remaining = buffer_size - _chunk_size

      begin
        length = IO.copy io, buffer, remaining
        _chunk_size += length
        stream_size += length
      rescue exception
        buffer.rewind
        call = yield buffer, stream_size, true, true

        length = 0_i32
        finished = true

        next
      end

      case {_chunk_size, length}
      when {buffer_size, length}
        buffer.rewind
        call = yield buffer, stream_size, false, false

        buffer.clear
        _chunk_size = 0_i32
      when {_chunk_size, 0_i32}
        buffer.rewind
        call = yield buffer, stream_size, true, false

        finished = true
      end

      if call.is_a? Exception
        finished = true

        next
      end
    end

    buffer.close
    io.close rescue nil if sync_close
  end
end
