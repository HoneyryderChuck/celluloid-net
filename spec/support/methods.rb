def within_io_actor(&block)
  actor = WrapperActor.new
  actor.wrap(&block)
ensure
  actor.terminate if actor.alive? rescue nil
end
