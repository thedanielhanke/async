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

require 'async/scheduler'

RSpec.shared_examples_for Async::Scheduler do
	let(:order) {Array.new}
	
	describe '#spawn' do
		it 'can create a fiber' do
			fiber = subject.spawn do
			end
			
			expect(fiber).to be_kind_of Fiber
		end
	end
	
	describe '#resume' do
		it 'can #resume fiber' do
			fiber = subject.spawn do
				order << :a
			end
			
			subject.resume(fiber)
			expect(order).to be == [:a]
		end
		
		it 'exits into outer fiber' do
			child = nil
			
			parent = subject.spawn do
				order << :a
				
				child = subject.spawn do
					order << :c
					subject.yield
					order << :e
				end
				
				order << :b
				child.resume
				order << :d
			end
			
			order << :A
			subject.resume(parent)
			order << :B
			subject.resume(child)
			order << :C
			
			expect(order).to be == [:A, :a, :b, :c, :d, :B, :e, :C]
		end
	end
	
	describe '#yield' do
		it 'can #yield fiber' do
			fiber = subject.spawn do
				order << :a
				subject.yield
				order << :b
			end
			
			subject.resume(fiber)
			subject.resume(fiber)
			
			expect(order).to be == [:a, :b]
		end
	end
end

RSpec.describe Async::Scheduler do
	it_should_behave_like Async::Scheduler
end

RSpec.describe Async::TransferScheduler do
	it_should_behave_like Async::Scheduler
end
