module Celluloid
  # Reopening the thread class to define the time handlers and pointing them to celluloid respective methodsx
  class Thread < ::Thread
    def initialize(*)
      self.timeout_handler = Celluloid.method(:timeout).to_proc
      self.sleep_handler = Celluloid::method(:sleep).to_proc
      super
    end
  end

  # Hopefully will be part of celluloid someday...
  
  # Pushed the timeout logic out of the actor and into the module, as this seems general purpose enough
  def self.timeout(duration, klass = nil)
    bt = caller
    task = Task.current
    klass ||= TaskTimeout
    timers = Thread.current[:celluloid_actor].timers
    timer = timers.after(duration) do
      exception = klass.new("execution expired")
      exception.set_backtrace bt
      task.resume exception
    end unless duration.nil?
    yield
  ensure
    timer.cancel if timer
  end

  class Actor
    # Using the module method now instead of doing everything by itself.
    def timeout(*args)
      Celluloid::timeout(*args) { yield }
    end
    private :timeout
  end
end


