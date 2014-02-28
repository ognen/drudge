require 'spec_helper'
require 'hoister/cli/parsers/parse_results'

module Hoister
  class Cli
    module Parsers

      describe ParseResults do
        include ParseResults

        describe ParseResult do 

          describe ".+" do 
            context "Success() + Success()" do 
              it "is a a Success where '+' is applied to the underlying ParseValue" do
                expect(Success(Single(1), [2, 3]) + Success(Single(2), [3])).to eq Success(Seq([1, 2]), [3])
                expect(Success(Empty(), [2, 3]) + Success(Single(2), [3])).to eq Success(Single(2), [3])
                expect(Success(Seq([1, 2]), [3, 4]) + Success(Single(3), [4])).to eq (Success(Seq([1, 2, 3]), [4]))
              end
            end
            context "Success() + NoSuccess()" do
              it "is a Failure()" do 
                expect(Success(Single(1), [2, 3]) + Failure("error", [3])).to eq Failure("error", [3])
              end
            end

            context "NoSuccess() + Success()" do
              it "is a Failure()" do
                expect(Failure("error", [3]) + Success(Single(2), [3, 4])).to eq Failure("error", [3])
              end
            end
          end
        end

        describe ".success?" do 
          it "returns true for a Success()" do
            expect(Success(Single(1), []).success?).to be_true
          end

          it "returns false for all NoSuccess() parse results" do
            expect(Failure("error", []).success?).to be_false
            expect(Error("error", []).success?).to be_false
          end
        end
      end

    end
  end
end