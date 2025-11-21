#!/usr/bin/env ruby
Dir[File.join(__dir__, '*_spec.rb')].sort.each { |file| require file }
