require 'spec_helper'
require 'drudge/parsers/tokenizer'

class Drudge

  module Parsers
    describe Tokenizer do

      describe ".tokenize" do

        it "converts an array of command line arguments into an array of sexps" do
          tokens = Tokenizer.tokenize(%w[hello world])

          expect(tokens).to be_kind_of(Enumerable)
          
          tokens.each do |type, arg, meta|
            expect(type).to eq :val
            expect(arg).to be_kind_of(String)
            expect(meta).to include(:loc)
          end
        end

        it "converts an ordinary argument 'arg' into the sexp [:val, 'arg']" do
          tokens = Tokenizer.tokenize(%w[hello world])

          expect(tokens).to eq [[:val, 'hello', {loc: [0, 0, 5]}],
                                [:val, 'world', {loc: [1, 0, 5]}]]
        end

        it "converts a keyword argument into the sexp [:--, 'arg']" do 
          tokens = Tokenizer.tokenize(%w[hello --arg])

          expect(tokens).to eq [[:val, 'hello', {loc: [0, 0, 5]}],
                                [:"--", 'arg', {loc: [1, 0, 5]}]]
        end

        it "converts a '--keyword=value' argument into [[:--, 'keyword'], [:=], [:val, 'value']" do
          tokens = Tokenizer.tokenize(%w[hello --keyword=value])
          
          expect(tokens).to eq [[:val, 'hello', {loc: [0, 0, 5]}],
                                [:'--', 'keyword', {loc: [1, 0, 9]}],
                                [:'=', {loc: [1, 9, 1]}],
                                [:val, 'value', {loc: [1, 10, 5]}]]
        end

        it "converts the '--' argument into [:!--] " do
          tokens = Tokenizer.tokenize(%w[hello --])

          expect(tokens).to eq [[:val, 'hello', {loc: [0, 0, 5]}],
                                [:"!--", {loc: [1, 0, 2]}]]
        end

      end

      describe ".untokenize" do
        let(:sexps) { [[:val, 'hello', {loc: [0, 0, 5]}],
                       [:val, 'dear', {loc: [1, 0, 4]}],
                       [:val, 'world', {loc: [2, 0, 5]}]] }

        it "converts an array of s-exps into a string" do
          expect(Tokenizer.untokenize(sexps)).to eq "hello dear world"
        end
      end

      describe ".underline_token" do 
        let(:sexps) { [[:val, 'hello', {loc: [0, 0, 5]}],
                       [:val, 'dear', {loc: [1, 0, 4]}],
                       [:val, 'world', {loc: [2, 0, 5]}]] }

        it "underlines first token" do
          expect(Tokenizer.underline_token(sexps, sexps[0])).to eq "~~~~~"
        end

        it "underlines the second token" do
          expect(Tokenizer.underline_token(sexps, sexps[1])).to eq "      ~~~~"
        end

        it "underlines the third token" do
          expect(Tokenizer.underline_token(sexps, sexps[2])).to eq "           ~~~~~"
        end

        it "underlines the end of string when token is nil" do
          expect(Tokenizer.underline_token(sexps, nil)).to eq "                 ^"
        end

        it "can be told which underline char to use" do
          expect(Tokenizer.underline_token(sexps, sexps[0], underline_char: "-")).to eq "-----"
        end
      end

    end

  end
end

