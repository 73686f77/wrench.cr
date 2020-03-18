abstract class IO
  class CopyException < Exception
    property count : UInt64?

    def initialize(@message : String? = nil, @cause : Exception? = nil, @count : UInt64? = nil)
    end
  end

  def self.copy(src, dst, cause : Bool) : UInt64
    return copy src, dst unless cause

    buffer = uninitialized UInt8[4096_i32]
    count = 0_u64

    begin
      while (len = src.read(buffer.to_slice).to_i32) > 0_i32
        dst.write buffer.to_slice[0_i32, len]

        count += len
      end
    rescue ex
      CopyException.new message: String.new, cause: ex, count: count
    end

    count
  end
end
