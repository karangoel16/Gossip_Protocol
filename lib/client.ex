defmodule Project2.Client do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__,:ok,name: args)
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
          :add_state->
                map=%{}
                map=Map.put(map,"state",{name,1})
                map=Map.put(map,"balance",1)
                {:reply,"",{elem(state,0),map}}
          :line->#we need to add previous and the new state here
                var=Tuple.append(elem(state,0),msg)
                {:reply,"",{var,elem(state,1)}}
          :link->#we made this to check our network
                {:reply,state,state}
      end
    end
    def handle_cast({:msg , msg , name,type ,sleep},state) do
            wait_time=
            case tuple_size(elem(state,0)) do
                4->100
                5->100
                2->100
                _->100
            end
            #IO.puts wait_time
            var=:rand.uniform(tuple_size(elem(state,0)))
            case sleep do
                1->GenServer.cast({elem(elem(state,0),var-1)|>Integer.to_string|>String.to_atom,Node.self() },{:msg,msg,elem(elem(state,0),var-1),type,0})
                   Process.sleep(wait_time)
                   GenServer.cast({Integer.to_string(name)|>String.to_atom,Node.self()},{:msg,msg,name,type,1}) 
                {:noreply,state} 
                0->""
            end
            case type do
                "gossip"->
                    map=elem(state,1)
                    case Map.get(map,msg,0)>10 do
                    true->
                        GenServer.call({:Server,Node.self()},{:add_val,name},:infinity)
                        {:noreply,state}
                    false->
                        map=Map.put(map,msg,Map.get(map,msg,0)+1)
                        GenServer.cast({elem(elem(state,0),var-1)|>Integer.to_string|>String.to_atom,Node.self() },{:msg,msg,elem(elem(state,0),var-1),type,0})
                        Process.sleep(wait_time)
                        GenServer.cast({Integer.to_string(name)|>String.to_atom,Node.self()},{:msg,msg,name,type,1})
                        {:noreply,{elem(state,0),map}}
                    end
                "push-sum"->
                        map=elem(state,1)
                        case tuple_size(msg)==0 do
                            true->
                                {s,w}=Map.get(map,"state")
                                GenServer.cast({elem(elem(state,0),var-1)|>Integer.to_string|>String.to_atom,Node.self() },{:msg,{s/2,w/2},elem(elem(state,0),var-1),type,sleep})
                                #spawn(fn->cast_call(:msg,{s/2,w/2},name,type)end)
                                map=Map.put(map,"state",{s+s/2,w+w/2})
                                map=Map.put(map,"balance",1)
                                {:noreply,{elem(state,0),map}}
                            false->
                                case Map.get(map,"balance")>=3 do
                                    true->
                                        GenServer.cast({elem(elem(state,0),var-1)|>Integer.to_string|>String.to_atom,Node.self() },{:msg,msg,elem(elem(state,0),var-1),type,sleep})
                                        #this is to terminate the node
                                        GenServer.call({:Server,Node.self()},{:add_val,name},:infinity)
                                    {:noreply,state}
                                    false->
                                        val=Map.get(map,"state")
                                        s=elem(val,0)
                                        w=elem(val,1)
                                        s1=elem(msg,0)
                                        w1=elem(msg,1)
                                        map=
                                        case abs(((s1+(s/2))/(w1+(w/2)))-(s/w))<:math.pow(10,-10) do
                                            true->Map.put(map,"balance",Map.get(map,"balance")+1)
                                            false->Map.put(map,"balance",1)
                                        end
                                        map=Map.put(map,"state",{s1/2+s,w1/2+w})
                                        GenServer.cast({elem(elem(state,0),var-1)|>Integer.to_string|>String.to_atom,Node.self() },{:msg,{s1/2,w1/2},elem(elem(state,0),var-1),type,sleep})
                                        {:noreply,{elem(state,0),map}}
                                end
                                
                        end
            end
        end

    def loop do
        Process.sleep(1_000_000)
    end
end
