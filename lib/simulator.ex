defmodule Simulator do
   use GenServer
    
    def main(username,weight,numClients) do
        
        IO.puts "simulating"
        hashtaglist = ["#karan","#srishti","#aru","#football","#apple","#mango","#realmadrid","#india","#tweeter","#beer","#rum","#vodka"]

        all_users_list = Test.create_users_list(numClients,[])
        num = 1..numClients
        num_list = Enum.to_list(num)

        #Test.random_tweets_with_hashtag(hashtaglist,100,num_list)
        #Test.random_tweets_with_mention(100,num_list)

        IO.puts " done hashtag mention"
        # for x <- 1..3 do
        #     spawn fn -> Test.simulate_connect_disconnect(num_list) end
        # end

        
        # Test.random_follow_tweet(username,weight,num_list) 
        
        Test.random_tweet(username,weight, num_list)
        :timer.sleep(1000)
        Test.random_follow(username,weight, num_list)

        # IO.puts "follow retweet"
        # Test.sim_retweet(username)



        
        GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())},{:print_state, "mainserver"}) 
        spawn fn -> Mainprog.search_hashtag("#realmadrid") end
        spawn fn -> Mainprog.search_mention("@user100") end


        IO.puts "done everything"

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

defmodule Test do
        


        def getZipfDist(numberofClients) do
            distList=[]
            s=1
            c=getConstantValue(numberofClients,s)
            distList=Enum.map(1..numberofClients,fn(x)->:math.ceil((c*numberofClients)/:math.pow(x,s)) end)
            distList
        end

        def getConstantValue(numberofClients,s) do
            k=Enum.reduce(1..numberofClients,0,fn(x,acc)->:math.pow(1/x,s)+acc end )
            k=1/k
            k
        end

        def simulate_connect_disconnect(num_list) do
            #:timer.sleep(1000)
            
          
            dead = Enum.random(num_list)
            spawn fn -> Mainprog.go_offline("user"<>to_string(dead)) end
            #:timer.sleep(100)
            if(Process.whereis(String.to_atom("user"<>to_string(dead))) == nil) do
                IO.puts "--------------------------------------------------------------------------------------------------------------------------------------"
                IO.puts "user" <> to_string(dead) <> " went offline"
            end
            :timer.sleep(2000)
            Mainprog.go_online("user"<>to_string(dead),"pass"<>to_string(dead))
            if(Process.whereis(String.to_atom("user"<>to_string(dead))) != nil) do
                GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>Mainprog.get_ip_addr())},{:is_online, {"user"<>to_string(dead)}}) 
                IO.puts "--------------------------------------------------------------------------------------------------------------------------------------"
                IO.puts "user" <> to_string(dead) <> " came online"
            end
        end
       
        
        def create_users_list(num,list) do
            if num > 0 do
                user = "user" <> Integer.to_string(num)
                list = list ++ [user]
                create_users_list(num-1,list) 
            else
                list
            end
        end

        def random_tweets_with_hashtag(hashtaglist,num,num_list) do
            if num >0 do
                cur = Enum.random(num_list)
                cur_user = "user" <> to_string(cur)
                if(Process.whereis(String.to_atom(cur_user)) != nil) do
                        spawn fn -> Mainprog.tweet(cur_user,"I am tweet with hashtag " <> Enum.random(hashtaglist)) end
                end
                random_tweets_with_hashtag(hashtaglist,num-1,num_list)
            end
        end


        def sim_retweet(username) do
            if(Process.whereis(String.to_atom(username)) != nil) do
                retweeter_state = GenServer.call(String.to_atom(username), {:get_state, {}})

            dashboard_list = Map.get(retweeter_state,"dashboard")
            size = Enum.count(dashboard_list)
            num_retweets = round(:math.ceil(0.30*size))

            for y <- 1..num_retweets do
                if(Enum.count(dashboard_list)!=0) do
                    retweet = Enum.random(dashboard_list)
                    id = elem(retweet,0)
                    tweeter = elem(retweet,2)
                    dashboard_list = List.delete(dashboard_list, retweet)
                    if(username != tweeter) do
                        if(Process.whereis(String.to_atom(username)) != nil) do
                            spawn fn -> Mainprog.retweet(username,tweeter,id) end
                        end
                    end
                end
            end
            end
        end

        def random_tweets_with_mention(num,num_list) do
            if num > 0 do
                cur = Enum.random(num_list)
                cur_user = "user" <> to_string(cur)
                mention = Enum.random(num_list)
                mention_user = "@user"<> to_string(mention)
                if(cur != mention) do
                    if(Process.whereis(String.to_atom(cur_user)) != nil) do
                            spawn fn -> Mainprog.tweet(cur_user,"I am tweet with mention " <> "@user" <> to_string(Enum.random(num_list))) end
                    end    
                    random_tweets_with_mention(num-1,num_list)
                else
                    random_tweets_with_mention(num,num_list)
                end
            end
        end

        def random_tweet(cur_user, num, num_list) do
            if num > 0 do
                
                to_follow = Enum.random(num_list)
                IO.inspect to_follow
                if cur_user != "user"<>Integer.to_string(to_follow)  do

                    if(Process.whereis(String.to_atom(cur_user)) != nil) do
                                IO.puts "alive"
                                spawn fn -> Mainprog.tweet(cur_user,"I am Tweet") end

                    end
                            #IO.puts "hereee"
                    random_tweet(cur_user,num-1,num_list)
                    
                else
                    num_list = List.delete(num_list,to_follow)
                    random_tweet(cur_user,num,num_list)
                end
            
            end
            if(Process.whereis(String.to_atom(cur_user)) != nil) do
                 GenServer.call(String.to_atom(cur_user),{:print_state, "someone"}) 
            end
        end


        def random_follow(cur_user,num,num_list) do
            if num > 0 do
                #IO.puts num
                to_follow = Enum.random(num_list)
                #IO.inspect to_follow
                if(cur_user != "user"<>Integer.to_string(to_follow)) do
                    if(Process.whereis(String.to_atom("user"<> Integer.to_string(to_follow))) != nil) do
                            num_list = List.delete(num_list,to_follow)
                            #IO.inspect num_list
                            IO.puts "---------"
                            spawn fn -> Mainprog.follow_someone("user"<> Integer.to_string(to_follow),cur_user) end
                            random_follow(cur_user,num-1,num_list)
                    else 
                        random_follow(cur_user,num,num_list)
                    end
                    
                else
                    num_list = List.delete(num_list,to_follow)
                    random_follow(cur_user,num,num_list)
                end
            end
        end 

        def random_follow_tweet(cur_user,num,num_list) do
            #IO.puts "curr user is " <> to_string(cur_user)
            if num > 0 do
                IO.puts num

                to_follow = Enum.random(num_list)
                IO.inspect to_follow
                if cur_user != "user"<>Integer.to_string(to_follow)  do
                    if(Process.whereis(String.to_atom("user"<> Integer.to_string(to_follow))) != nil) do
                            num_list = List.delete(num_list,to_follow)
                            #IO.inspect num_list
                            IO.puts "---------"
                            spawn fn -> Mainprog.follow_someone("user"<> Integer.to_string(to_follow),cur_user) end
                    
                    else 
                        random_follow_tweet(cur_user,num,num_list)
                    
                    end

                    if(Process.whereis(String.to_atom(cur_user)) != nil) do
                                IO.puts "alive"
                                spawn fn -> Mainprog.tweet(cur_user,"I am Tweet") end

                    end
                            #IO.puts "hereee"
                            random_follow_tweet(cur_user,num-1,num_list)
                    
                else
                    num_list = List.delete(num_list,to_follow)
                    random_follow_tweet(cur_user,num,num_list)
                end
            
            end
            if(Process.whereis(String.to_atom(cur_user)) != nil) do
                GenServer.call(String.to_atom(cur_user),{:print_state, "someone"}) 
            end
        end    
end