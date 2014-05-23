# Extensions to standard classes

module Ext
  refine String

    # undents the string by removeing as much leading space
    # as the first line has. 
    #
    # Useful for cases like: 
    #   puts <<-EOS.undent
    #     bla bla bla
    #     bla 
    #   EOS
    #
    def undent
      gsub(/^.{#{slice(/^ +/).length}}/, '')
    end 
  end
end

using Ext