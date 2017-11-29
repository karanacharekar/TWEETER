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
      {_, [input], _} = OptionParser.parse(args)
      
      if(input=="server") do
          Server.main()
      end

      if(input=="client") do
          Mainprog.main()  
      end

      IO.puts " Wrong input " 
   end
    

   def get_ip_addr do 
    {:ok,lst} = :inet.getif()
    z = elem(List.last(lst),0) 
    if elem(z,0)==127 do
    x = elem(List.first(lst),0)
    addr =  to_string(elem(x,0)) <> "." <>  to_string(elem(x,1)) <> "." <>  to_string(elem(x,2)) <> "." <>  to_string(elem(x,3))
    else
    x = elem(List.last(lst),0)
    addr =  to_string(elem(x,0)) <> "." <>  to_string(elem(x,1)) <> "." <>  to_string(elem(x,2)) <> "." <>  to_string(elem(x,3))
    end
    addr  
  end


end   
