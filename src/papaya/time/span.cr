struct Time::Span
  def total_microseconds : Float64
    total_nanoseconds / NANOSECONDS_PER_MICROSECOND
  end
end
