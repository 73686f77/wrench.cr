module Stream
  class Through
    getter reader : IO::FileDescriptor
    getter writer : IO::FileDescriptor

    def initialize(@reader, @writer)
    end

    def self.new
      reader, writer = IO.pipe

      new reader, writer
    end

    def all_close
      reader.close rescue nil
      writer.close rescue nil
    end
  end
end
