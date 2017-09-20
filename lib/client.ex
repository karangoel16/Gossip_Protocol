defmodule Project2.Client do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__,:ok,name: args)
        #Project2.Exdistutils.start_distributed(Integer.to_string(args)|>String.to_atom)
        #IO.inspect Node.self()
        #IO.inspect  :"project2@10.228.7.203"
    end

    def init(:ok) do
        {:ok,{{},%{}}}
    end
    def cast_call(check,msg,name,type) do
        GenServer.cast({Integer.to_string(name)|>String.to_atom,Node.self()},{check,msg,name,type})
    end
    def handle_call({check , msg , name},_from,state) do
      case check do
          
          :complete->
                var=Enum.to_list(1..String.to_integer(msg))|>List.to_tuple
                var=Tuple.delete_at(var,name-1)#delete yourself from list
                temp={var,elem(state,1)}
                {:reply,"",temp }
          :line->#we need to add previous and the new state here
                var=Tuple.append(elem(state,0),msg)
                {:reply,"",{var,elem(state,1)}}
          :link->#we made this to check our network
                {:reply,state,state}
      end
    end
    def handle_cast({:msg , msg , name,type},state) do
            case type do
                :gossip->
                    map=elem(state,1)
                    case Map.get(map,msg,0)>10 do
                    true->var=:rand.uniform(tuple_size(elem(state,0)))
                    GenServer.call({:Server,Node.self()},{:add_val,name},:infinity)
                    {:noreply,state}
                    false->
                        var=:rand.uniform(tuple_size(elem(state,0)))
                        map=Map.put(map,msg,Map.get(map,msg,0)+1)
                        GenServer.cast({elem(elem(state,0),var-1)|>Integer.to_string|>String.to_atom,Node.self() },{:msg,msg,elem(elem(state,0),var-1),type})
                        spawn(fn->cast_call(:msg,msg,name,type)end)
                        {:noreply,{elem(state,0),map}}
                end
            end
        end

    def loop do
        Process.sleep(1_000_000)
    end
end
