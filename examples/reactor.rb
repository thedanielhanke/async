#!/usr/bin/env ruby

require 'fiber'

module Async
	class Reactor
		def initialize
			@fiber = nil
			@waiting = []
		end
		
		def yield
			@fiber.transfer
		end
		
		def resume(fiber)
			previous = @fiber
			
			@fiber = Fiber.current
			fiber.transfer
			
			@fiber = previous
		end
		
		def async(&block)
			fiber = Fiber.new do
				block.call
				self.yield
			end
			
			resume(fiber)
		end
		
		# Wait for some event...
		def wait
			@waiting << Fiber.current
			self.yield
		end
		
		def run
			while @waiting.any?
				fiber = @waiting.pop
				resume(fiber)
			end
		end
	end
end

reactor = Async::Reactor.new

reactor.async do
	puts "Hello World"
	reactor.async do
		puts "Goodbye World"
		reactor.wait
		puts "I'm back!"
	end
	puts "Foo Bar"
end

puts "Running"
reactor.run
puts "Finished"

