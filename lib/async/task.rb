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
require 'forwardable'

require_relative 'node'
require_relative 'condition'

module Async
	
  # The Async::Interrupt class to manage
  # exceptions when they happen, as they do.
  # @author Samuel Williams  
  class Interrupt < Exception
	end

  # The Async::Task class manages the logic for tasks
  # as they come up.
  # @author Samuel Williams  
	class Task < Node
		extend Forwardable
	
    # Yield the unerlying +result+ for the task. If the result
    # is an Exception, then that result will be raised an its
    # exception.
    # @return [Object] result of the task
    # @raise [Exception] if the result is an exception
    # @yield [result] result of the task if a block if given.
		def self.yield
			if block_given?
				result = yield
			else
				result = Fiber.yield
			end
			
			if result.is_a? Exception
				raise result
			else
				return result
			end
		end
	
    # Create a new task.
    # @param ios [Array<IO>] an array of IO objects such as TCPServer, Socket, ect. 
    # @param reactor [Async::Reactor] 
    # @return [void]
		def initialize(ios, reactor)
      if parent = Task.current?
				super(parent)
			else
				super(reactor)
			end
			
			@ios = Hash[
				ios.collect{|io| [io.fileno, reactor.wrap(io, self)]}
			]
			
			@reactor = reactor
			
			@status = :running
			@result = nil
			
			@condition = nil
			
			@fiber = Fiber.new do
				set!
				
				begin
					@result = yield(*@ios.values, self)
					@status = :complete
					# Async.logger.debug("Task #{self} completed normally.")
				rescue Interrupt
					@status = :interrupted
					# Async.logger.debug("Task #{self} interrupted: #{$!}")
				rescue Exception => error
					@result = error
					@status = :failed
					# Async.logger.debug("Task #{self} failed: #{$!}")
					raise
				ensure
					# Async.logger.debug("Task #{self} closing: #{$!}")
					close
				end
			end
		end
	  
    # Show the current status of the task as a string.
    # @todo (picat) Add test for this method?  
    def to_s
      "#{super}[#{@status}]"
		end


    # @attr ios [Array<IO>] The container for the associated IO objects.
		attr :ios
    
    # @attr ios [Reactor] The container for the associated Async::Reactor
		attr :reactor
		def_delegators :@reactor, :timeout, :sleep
    
    # @attr fiber [Fiber] The container for the associated underlying fiber.
		attr :fiber
		def_delegators :@fiber, :alive?
    
    # @attr status [Symbol] 
		attr :status
    
    # @attr result [Object] 
		attr :result
		
    # Resume the current fiber associted with the +task+.
    # @return [void]
		def run
			@fiber.resume
		end
	
    # Retrieve the current result of the task.
    # @raise [RuntimeError] if the current fiber is itself
    # @return [Object]
		def result
			raise RuntimeError.new("Cannot wait on own fiber") if Fiber.current.equal?(@fiber)
			
			if running?
				@condition ||= Condition.new
				@condition.wait
			else
				Task.yield {@result}
			end
		end
		
		alias wait result
	
    # Stop the task and all of its children.
    # @return[void]  
		def stop
			@children.each(&:stop)
			
			if @fiber.alive?
				exception = Interrupt.new("Stop right now!")
				@fiber.resume(exception)
			end
		end
	
    # Provide a wrapper to an IO object with a Reactor.
    # @yield [Async::IO] a wrapped Async IO object.  
		def with(io)
			wrapper = @reactor.wrap(io, self)
			yield wrapper
		ensure
			wrapper.close
			io.close
		end
	
    # Bind a given IO object, wrapping it with a Reactor if
    # the IO object isn't already associated with the current task.
    # @todo (picat) Clarify this plz.   
		def bind(io)
			@ios[io.fileno] ||= reactor.wrap(io, self)
		end
	
    # Register a given IO with given interests to be able to monitor it.
    # @param io [IO]   
    # @param interests [Symbol]
    # @return [NIO::Monitor] 
		def register(io, interests)
			@reactor.register(io, interests)
		end
	
    # Return the current async task.
		# @return [Async::Task]
    # @raise [RuntimeError] if no async task is available.
    def self.current
			Thread.current[:async_task] or raise RuntimeError, "No async task available!"
		end

      
    # Check if there is a current task.
		# @return [Async::Task]
		def self.current?
			Thread.current[:async_task]
		end
	
    # Check if the task is running.
    # @return [Boolean]  
		def running?
			@status == :running
		end
		
		# Whether we can remove this node from the reactor graph.
    # @return [Boolean]  
		def finished?
			super && @status != :running
		end
	  
    # Close each IO objects.
    # @todo (picat) Clarify this.
		def close
			@ios.each_value(&:close)
			@ios = []
			
			consume
			
			if @condition
				@condition.signal(@result)
			end
		end
		
		private
	  
    # @api private  
    # Set the current task to itself.
    # @todo (picat) Clarify this.
		def set!
			# This is actually fiber-local:
			Thread.current[:async_task] = self
		end
	end
end
