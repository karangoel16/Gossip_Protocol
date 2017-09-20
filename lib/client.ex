defmodule Project2.Client do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__,:ok,name: args)
        #Project2.Exdistutils.start_distributed(Integer.to_string(args)|>String.to_atom)
        #IO.inspect Node.self()
        #IO.inspect  :"project2@10.228.7.203"
        loop()
    end

    def init(:ok) do
        {:ok,{{},%{}}}
    end
    def cast_call(check,msg,name) do
        GenServer.cast({Integer.to_string(name)|>String.to_atom,Node.self()},{check,msg,name})
    end
    def handle_cast({check , msg , name},state) do
      case check do
          :msg->map=elem(state,1)
                case Map.get(map,msg,0)>10 do
                    #Need to call GenServer and Stop it
                    true->
                        IO.puts("Request Full")
                    {:noreply,state}
                    false->var=:rand.uniform(tuple_size(elem(state,0)))
                           map=Map.put(map,msg,Map.get(map,msg,0)+1)
                           GenServer.cast({ String.to_atom(Integer.to_string(elem(elem(state,0),var-1))),Node.self() },{:msg,msg,elem(elem(state,0),var-1)})
                           cast_call(check,msg,name)
                           {:noreply,{elem(state,0),map}}
                    end
          :complete->
                var=Enum.to_list(1..String.to_integer(msg))|>List.to_tuple
                var=Tuple.delete_at(var,name-1)#delete yourself from list
                temp={var,elem(state,1)}
                IO.inspect temp
                {:noreply,temp }
          :line->#we need to add previous and the new state here
                var=Tuple.append(elem(state,0),msg)
                {:noreply,{var,elem(state,1)}}
          :link->#we made this to check our network
                {:noreply,state}
      end
    end


    def loop do
        Process.sleep(1_000_000)
        loop()
    end
end
