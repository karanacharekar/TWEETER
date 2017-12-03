defmodule Tweeter do
    
    def main(args) do
        args |> parse_args 

        # startservid = spawn fn -> Server.main() end
        # :timer.sleep(1000)
        # IO.puts "Main reached"
        # startclient = spawn fn -> Mainprog.main() end
        # IO.gets ""
    end


    def parse_args([]) do
      IO.puts "No arguments given" 
    end    

  # THIS FUNCTION PARSES ARGUMENTS AND DECIDES BETWEEN SERVER AND CLIENT 

    def parse_args(args) do
      {_, input, _} = OptionParser.parse(args)
      type = Enum.at(input,0)
      if(type=="server") do
          Server.main()
      end

      if(type=="client") do
          prev = System.os_time(:millisecond)
          numClients = String.to_integer(Enum.at(input,1))
          Mainprog.main(numClients)
          next = System.os_time(:millisecond)
          diff = next - prev
          IO.puts "total time taken in secs"
          IO.inspect (diff/1000)
      end
      
      IO.puts " Wrong input " 
    end
    
end   
