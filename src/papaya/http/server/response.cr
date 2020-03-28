class HTTP::Server
  class Response
    def encoding? : Bool
      return false unless _compress_type = compress_type
      return false if _compress_type.identity?

      true
    end

    def compress_type : HTTP::CompressType?
      return unless encoding = @headers["Content-Encoding"]?

      HTTP::CompressType.parse? encoding
    end
  end
end
