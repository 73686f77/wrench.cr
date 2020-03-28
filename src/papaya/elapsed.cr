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
    return {weeks, Flag::Weeks} if weeks.to_i != 0_i32

    days = elapsed.total_days
    return {days, Flag::Days} if days.to_i != 0_i32

    hours = elapsed.total_hours
    return {hours, Flag::Hours} if hours.to_i != 0_i32

    minutes = elapsed.total_minutes
    return {minutes, Flag::Minutes} if minutes.to_i != 0_i32

    seconds = elapsed.total_seconds
    return {seconds, Flag::Seconds} if seconds.to_i != 0_i32

    milliseconds = elapsed.total_milliseconds
    return {milliseconds, Flag::MilliSeconds} if milliseconds.to_i != 0_i32

    microseconds = elapsed.total_microseconds
    return {microseconds, Flag::MicroSeconds} if microseconds.to_i != 0_i32

    nanoseconds = elapsed.total_nanoseconds
    return {nanoseconds, Flag::NanoSeconds} if nanoseconds.to_i != 0_i32
  end

  def self.flag_to_text(flag : Flag) : String?
    case flag
    when .weeks?
      "w"
    when .days?
      "d"
    when .hours?
      "h"
    when .minutes?
      "m"
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

    String.build do |io|
      io << tuple.first.round round
      io << Elapsed.flag_to_text tuple.last
    end
  end
end
