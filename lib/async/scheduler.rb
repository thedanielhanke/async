# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'fiber'

module Async
	class Scheduler
		def spawn(*args, &block)
			Fiber.new(*args, &block)
		end
		
		def resume(fiber, *args)
			fiber.resume *args
		end
		
		def yield(*args)
			Fiber.yield(*args)
		end
	end
	
	class TransferScheduler
		def initialize
			# This is where we come back to when calling `#yield`.
			@fiber = nil
		end
		
		attr :fiber
		
		def spawn(*args, &block)
			Fiber.new(*args, &block)
		end
		
		def resume(fiber, *args)
			# if fiber.inspect =~ /created/
			# 	@fiber = Fiber.current
			# 	fiber.resume
			# else
				previous = @fiber
				
				@fiber = Fiber.current
				
				fiber.transfer(*args)
				
				@fiber = previous
			# end
		end
		
		def yield(*args)
			@fiber.transfer(*args)
		end
	end
end
