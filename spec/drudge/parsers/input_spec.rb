$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'drudge/parsers/input'

class Drudge
  module Parsers

    describe Input do
      context "Input from an array [1, 2, 3, 4]" do
        subject { Input.from_array([1, 2, 3, 4]) }

        it "returns 1 for #peek" do
          expect(subject.peek).to eq 1
        end

        it "is not empty" do
          expect(subject.empty?).to be_false
        end

        it "returns a new Input on #next that points to the remainder of the intput" do
          n = subject.next

          expect(n.peek).to eq 2
          expect(n.empty?).to be_false
        end

        it "allows calls to #next multiple times" do
          three = subject.next.next
          two = subject.next

          expect(three.peek).to eq 3
          expect(two.peek).to eq 2
        end

        it "returns an empty input when next is called past the last element" do
          empty = subject.next.next.next.next

          expect(empty.empty?).to be_true
        end
      end

      context "Empty input" do
        subject { Input.from_array([]) }

        it "is empty" do
          expect(subject.empty?).to be_true
        end

        it "returns an empty input on next" do
          expect(subject.next.empty?).to be_true
        end

        it "raises a StopIteration error on peek" do
          expect { subject.peek }.to raise_error(StopIteration)
        end
      end

      context "Input from a basic Enumerator" do
        before do
          @enumerator = Enumerator.new do |yielder|
            yielder.yield "one"
            yielder.yield "two"
            yielder.yield "three"
          end
        end

        subject { Input.from_enumerator(@enumerator) }

        it "is not empty" do
          expect(subject.empty?).to be_false
        end

        it "peeks at 'one'" do
          expect(subject.peek).to eq "one"
        end

        it "can be used as a value" do
          one = subject
          three = subject.next.next
          two = subject.next

          expect(one.peek).to eq "one"
          expect(two.peek).to eq "two"
          expect(three.peek).to eq "three"
        end
      end
    end
  end
end