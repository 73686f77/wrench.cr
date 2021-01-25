class HTTP::WebSocket
  def run(auto_process : Bool)
    loop do
      begin
        info = @ws.receive @buffer
      rescue
        @on_close.try &.call CloseCode::AbnormalClosure, String.new
        @closed = true

        break
      end

      case info.opcode
      when .ping?
        @current_message.write @buffer[0_i32, info.size]

        if info.final
          message = @current_message.to_s
          @on_ping.try &.call message
          pong message unless closed? if auto_process
          @current_message.clear
        end
      when .pong?
        @current_message.write @buffer[0_i32, info.size]

        if info.final
          @on_pong.try &.call @current_message.to_s
          @current_message.clear
        end
      when .text?
        @current_message.write @buffer[0_i32, info.size]

        if info.final
          @on_message.try &.call @current_message.to_s
          @current_message.clear
        end
      when .binary?
        @current_message.write @buffer[0_i32, info.size]

        if info.final
          @on_binary.try &.call @current_message.to_slice
          @current_message.clear
        end
      when .close?
        @current_message.write @buffer[0_i32, info.size]

        if info.final
          @current_message.rewind

          if @current_message.size >= 2_i32
            code = @current_message.read_bytes(UInt16, IO::ByteFormat::NetworkEndian).to_i
            code = CloseCode.new code
          else
            code = CloseCode::NoStatusReceived
          end

          message = @current_message.gets_to_end

          @on_close.try &.call code, message
          close unless closed? if auto_process

          @current_message.clear

          break
        end
      when Protocol::Opcode::CONTINUATION
        # TODO: (asterite) I think this is good, but this case wasn't originally handled
      end
    end
  end

  def self.accept(socket : IO)
    begin
      request = HTTP::Request.from_io socket
      raise Exception.new "BadRequest" unless request.is_a? HTTP::Request
      raise Exception.new "BadRequest" unless websocket_upgrade_request? request

      response = HTTP::Server::Response.new socket
      version = request.headers["Sec-WebSocket-Version"]?

      unless version == WebSocket::Protocol::VERSION
        response.status = :upgrade_required
        response.headers["Sec-WebSocket-Version"] = WebSocket::Protocol::VERSION
        response.upgrade { }

        raise Exception.new "Unknown WebSocket Version"
      end

      unless key = request.headers["Sec-WebSocket-Key"]?
        response.respond_with_status :bad_request
        response.upgrade { }

        raise Exception.new "Unknown Sec-WebSocket-Key"
      end

      accept_code = WebSocket::Protocol.key_challenge key

      response.status = :switching_protocols
      response.headers["Upgrade"] = "websocket"
      response.headers["Connection"] = "Upgrade"
      response.headers["Sec-WebSocket-Accept"] = accept_code

      response.upgrade { }
    rescue ex
      socket.close
      raise ex
    end
  end

  def self.handshake(socket : IO, host : String, port : Int32, path : String = "/", headers : HTTP::Headers = HTTP::Headers.new) : Protocol
    begin
      random_key = Base64.strict_encode StaticArray(UInt8, 16_i32).new { rand(256_i32).to_u8 }

      headers["Host"] = "#{host}:#{port}"
      headers["Connection"] = "Upgrade"
      headers["Upgrade"] = "websocket"
      headers["Sec-WebSocket-Version"] = Protocol::VERSION
      headers["Sec-WebSocket-Key"] = random_key

      path = "/" if path.empty?
      handshake = HTTP::Request.new "GET", path, headers
      handshake.to_io socket
      socket.flush
      handshake_response = HTTP::Client::Response.from_io socket

      unless handshake_response.status.switching_protocols?
        raise Socket::Error.new "Handshake got denied. Status code was #{handshake_response.status.code}."
      end

      challenge_response = Protocol.key_challenge random_key

      unless handshake_response.headers["Sec-WebSocket-Accept"]? == challenge_response
        raise Socket::Error.new "Handshake got denied. Server did not verify WebSocket challenge."
      end
    rescue ex
      socket.close
      raise ex
    end

    Protocol.new socket, masked: true
  end

  def self.websocket_upgrade_request?(request : HTTP::Request)
    return false unless upgrade = request.headers["Upgrade"]?
    return false unless 0_i32 == upgrade.compare "websocket", case_insensitive: true

    request.headers.includes_word? "Connection", "Upgrade"
  end
end
