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

require 'set'

module Async
  # The Async Condition which all Tasks inherit from.
  # @author Samuel Williams
	class Node
		# Create a new node. 
    def initialize(parent = nil)
			@children = Set.new
			@parent = nil
			
			if parent
				self.parent = parent
			end
		end
		

		# @attr parent [Node, nil]
    attr :parent
		# @attr children [Set<Node>]
		attr :children
		
		# Attach this node to an existing parent.
		# @return [void]
    def parent=(parent)
			return if @parent.equal?(parent)
			
			if @parent
				@parent.reap(self)
				@parent = nil
			end
			
			if parent
				@parent = parent
				@parent.children << self
			end
		end
	
    # Check if the children set is empty.
    # @return [Boolean]  
		def finished?
			@children.empty?
		end
	
    # If the node is a parent and has no children
    # then the parent will reap itself, consume itself
    # and reduce itself to nil.
    #
    # Very dark, I know.
    #
    # @return[void]  
		def consume
			if @parent && finished?
				@parent.reap(self)
				@parent.consume
				@parent = nil
			end
		end
	
    # Remove a given child node.
    # @param child [Node] 
		def reap(child)
      @children.delete(child)
		end
	end
end
