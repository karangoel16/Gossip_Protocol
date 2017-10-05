defmodule Project2 do
  use GenServer
  def start_link(args) do
    GenServer.start_link(__MODULE__,args,name: :Server)
  end
  def init(args) do
    {:ok,{MapSet.new(Enum.into(1..String.to_integer(args),[],fn(x)-> if GenServer.whereis({x|>Integer.to_string|>String.to_atom,Node.self()}) != nil do x end end)),%{}}}
  end

  def main(args\\[]) do
    if List.to_tuple(args)|>tuple_size<3 do
      :init.stop()
    end
    number_of_node=elem(List.to_tuple(args),0)
    number_of_node=
    case elem(List.to_tuple(args),1) do
      "2D"->:math.pow(number_of_node|>String.to_integer|>:math.sqrt|>:math.ceil|>round,2)|>round|>Integer.to_string
      "full"->number_of_node
      "line"->number_of_node
      "imp2D"->:math.pow(number_of_node|>String.to_integer|>:math.sqrt|>:math.ceil|>round,2)|>round|>Integer.to_string
    end
    IO.inspect Enum.map(1..String.to_integer(number_of_node),fn(x)->spawn(fn->Project2.Client.start_link(Integer.to_string(x)|>String.to_atom) end)end)
    Project2.Exdistutils.start_distributed(:project2)
    start_link(number_of_node) #this is where the server genserver starts
    IO.puts "... build topology"
    var=number_of_node|>String.to_integer|>:math.sqrt|>:math.ceil|>round
    type=elem(args|>List.to_tuple,2)
    com=MapSet.new(Enum.into(1..String.to_integer(number_of_node),[]))|>MapSet.to_list|>List.to_tuple
    case elem(List.to_tuple(args),1)|>String.to_atom do
      :full->Enum.map(1..String.to_integer(number_of_node),fn(x)->GenServer.call({Integer.to_string(x)|>String.to_atom,Node.self()},{:complete,com,x},:infinity)end)
      :line->Enum.map(2..String.to_integer(number_of_node),fn(x)->GenServer.call({Integer.to_string(x)|>String.to_atom,Node.self()},{:line,x-1,x},:infinity)end)
             #this is for backward adding of the nodes
             Enum.map(1..(String.to_integer(number_of_node)-1),fn(x)->GenServer.call({Integer.to_string(x)|>String.to_atom,Node.self()},{:line,x+1,x},:infinity)end)
             #this is for forward adding of the terminal in the state of the GenServer
      :"2D"->
            Enum.map(1..var,fn(row)->
              Enum.map(1..var,fn(col)->
                Enum.map(1..4,fn(x)->
                  temp=(row-1)*var+(col-1)+1
                  temp=case x do
                      1->temp+1;#moving ahead condition
                      2->temp-1;#moving backward condition
                      3->temp-var#moving col up
                      4->temp+var#moving col down
                    end
                  case temp<=0 || temp>var*var do
                    false->
                        GenServer.call({((row-1)*var+(col-1)+1)|>Integer.to_string|>String.to_atom,Node.self()},{:line,temp,(row-1)*var+(col-1)+1})
                    true->nil
                  end
                end)
              end)
             end)
      :imp2D->
        Enum.map(1..var,fn(row)->
        Enum.map(1..var,fn(col)->
          Enum.map(1..4,fn(x)->
            temp=(row-1)*var+(col-1)+1
            temp=case x do
                1->temp+1;#moving ahead condition
                2->temp-1;#moving backward condition
                3->temp-var#moving col up
                4->temp+var#moving col down
              end
            case temp<=0 || temp>var*var do
              false->GenServer.call({((row-1)*var+(col-1)+1)|>Integer.to_string|>String.to_atom,Node.self()},{:line,temp,((row-1)*var+(col-1)+1)},:infinity)
              true->nil
            end
            rand=:rand.uniform(var*var) #this is the random node which is connected
            GenServer.call({((row-1)*var+col)|>Integer.to_string|>String.to_atom,Node.self()},{:line,rand,((row-1)*var+col)},:infinity)
          end)
        end)
        end)
        end
        IO.puts ".... start protocol"
        GenServer.cast({:Server,Node.self()},{:add_time,:os.system_time(:millisecond)})
      case type do
        "gossip"->
          #we are testing failure in the system
          rand=number_of_node|>String.to_integer|>:rand.uniform
          GenServer.cast({rand|>Integer.to_string|>String.to_atom,Node.self()},{:msg,"hello",rand,type,0})
        "push-sum"->
          temp_val=
          case elem(List.to_tuple(args),1)|>String.to_atom do
            :full->number_of_node|>String.to_integer
            :line->number_of_node|>String.to_integer
            :"2D"->var*var
            :imp2D->var*var
          end
          Enum.map(1..temp_val,fn(x)->GenServer.call({x|>Integer.to_string|>String.to_atom,Node.self()},{:add_state,"",x},:infinity)end)
          #we are testing failure in the system
          rand=:rand.uniform(temp_val)
          GenServer.cast({rand|>Integer.to_string|>String.to_atom,Node.self()},{:msg,{},rand,type,0})
      end
      #Enum.map( Enum.take_random(Enum.map(1..String.to_integer(number_of_node),fn(x)->x end),elem(args|>List.to_tuple,3)|>String.to_integer),fn(x)->GenServer.stop({x|>Integer.to_string|>String.to_atom,Node.self()})end);
    loop()
  end

  def handle_cast({check,time},state) do
    case check do
      :add_time->{:noreply,Tuple.append(state,time)}
      :check_state->
        val=elem(state,0)#we will take out the first mapset
        val=MapSet.new(Enum.into(MapSet.to_list(val),[],fn(x)-> if GenServer.whereis({x|>Integer.to_string|>String.to_atom,Node.self()}) != nil do x end end))#then we will delete from that value
        val=MapSet.delete(val,nil)
        state=Tuple.delete_at(state,0)
        {:noreply,Tuple.insert_at(state,0,val)}
    end
  end

  def handle_call({check,name},_from,state) do
    case check do
      :add_val->
        map=Map.put(elem(state,1),name,1)
        state=Tuple.delete_at(state,1)
        state=Tuple.insert_at(state,1,map)
        if length(Map.to_list(elem(state,1)))==length(MapSet.to_list(elem(state,0))) do
          IO.puts(:os.system_time(:millisecond)-elem(state,2))
          Enum.map(MapSet.to_list(elem(state,0)),fn(x)->GenServer.stop({Integer.to_string(x)|>String.to_atom,Node.self()})end)
          Process.exit(self(),:normal)
        end
        {:reply,"",state}
      :link->#we made this to check our network
      {:reply,state,state}
    end

  end

  def loop do
    GenServer.cast({:Server,Node.self()},{:check_state,""})
    Process.sleep(1000)
    loop()
  end
end
