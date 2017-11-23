defmodule Tweeter do
    
     def main(args) do
        startservid = spawn fn -> Server.main() end
        :timer.sleep(1000)
        IO.puts "Main reached"
        startclient = spawn fn -> Mainprog.main() end
        IO.gets ""
    end
    
end   
