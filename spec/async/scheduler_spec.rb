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
	let(:target) {double}
	
	describe '#spawn' do
		it 'can create a fiber' do
			fiber = subject.spawn do
			end
			
			expect(fiber).to be_kind_of Fiber
		end
	end
	
	describe '#resume' do
		it 'can #resume fiber' do
			expect(target).to receive(:mark)
			
			fiber = subject.spawn do
				target.mark
			end
			
			subject.resume(fiber)
		end
		
		it 'exits into outer fiber' do
			expect(target).to receive(:mark).twice
			
			parent = subject.spawn do
				child = subject.spawn do
					target.mark
				end
				
				child.resume
				target.mark
			end
			
			subject.resume(parent)
		end
	end
	
	describe '#yield' do
		it 'can #yield fiber' do
			expect(target).to receive(:mark).twice
			
			fiber = subject.spawn do
				target.mark
				subject.yield
				target.mark
			end
			
			subject.resume(fiber)
			subject.resume(fiber)
		end
	end
end

RSpec.describe Async::Scheduler do
	it_should_behave_like Async::Scheduler
end

RSpec.describe Async::TransferScheduler do
	it_should_behave_like Async::Scheduler
end
