module Elapsed
  enum Flag
    Weeks
    Days
    Hours
    Minutes
    Seconds
    MilliSeconds
    MicroSeconds
    NanoSeconds
  end

  def self.to_tuple(elapsed : Time::Span) : Tuple(Float64, Flag)?
    weeks = elapsed.total_weeks
    return Tuple.new weeks, Flag::Weeks if weeks.to_i != 0_i32

    days = elapsed.total_days
    return Tuple.new days, Flag::Days if days.to_i != 0_i32

    hours = elapsed.total_hours
    return Tuple.new hours, Flag::Hours if hours.to_i != 0_i32

    minutes = elapsed.total_minutes
    return Tuple.new minutes, Flag::Minutes if minutes.to_i != 0_i32

    seconds = elapsed.total_seconds
    return Tuple.new seconds, Flag::Seconds if seconds.to_i != 0_i32

    milliseconds = elapsed.total_milliseconds
    return Tuple.new milliseconds, Flag::MilliSeconds if milliseconds.to_i != 0_i32

    microseconds = elapsed.total_microseconds
    return Tuple.new microseconds, Flag::MicroSeconds if microseconds.to_i != 0_i32

    nanoseconds = elapsed.total_nanoseconds
    return Tuple.new nanoseconds, Flag::NanoSeconds if nanoseconds.to_i != 0_i32
  end

  def self.flag_to_text(flag : Flag) : String?
    case flag
    when .weeks?
      "weeks"
    when .days?
      "days"
    when .hours?
      "hours"
    when .minutes?
      "min"
    when .seconds?
      "s"
    when .milli_seconds?
      "ms"
    when .micro_seconds?
      "µs"
    when .nano_seconds?
      "ns"
    end
  end

  def self.to_text(elapsed : Time::Span, round : Int32 = 2_i32) : String
    return String.new unless tuple = to_tuple elapsed
    String.build { |io| io << tuple.first.round(round) << flag_to_text tuple.last }
  end
end
