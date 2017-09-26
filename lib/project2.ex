defmodule Project2 do
  use GenServer
  def start_link(args) do
    GenServer.start_link(__MODULE__,args,name: :Server)
  end
  def init(args) do
    {:ok,{args|>String.to_integer,%{}}}
  end

  def main(args\\[]) do
    if List.to_tuple(args)|>tuple_size<3 do
      :init.stop()
    end
    number_of_node=elem(List.to_tuple(args),0)
    number_of_node=
    case elem(List.to_tuple(args),1) do
      "2d"->:math.pow(number_of_node|>String.to_integer|>:math.sqrt|>:math.ceil|>round,2)|>round|>Integer.to_string
      "full"->number_of_node
      "line"->number_of_node
      "Im2d"->:math.pow(number_of_node|>String.to_integer|>:math.sqrt|>:math.ceil|>round,2)|>round|>Integer.to_string
    end
    IO.inspect Enum.map(1..String.to_integer(number_of_node),fn(x)->spawn(fn->Project2.Client.start_link(Integer.to_string(x)|>String.to_atom) end)end)
    Project2.Exdistutils.start_distributed(:project2)
    start_link(number_of_node) #this is where the server genserver starts
    IO.puts "... build topology"
    var=number_of_node|>String.to_integer|>:math.sqrt|>:math.ceil|>round
    type=elem(args|>List.to_tuple,2)
    com=MapSet.new(Enum.into(1..String.to_integer(number_of_node),[]))
    #com=MapSet.put(MapSet.new,Enum.to_list(1..String.to_integer(number_of_node))|>List.to_tuple)
    case elem(List.to_tuple(args),1)|>String.to_atom do
      :full->Enum.map(1..String.to_integer(number_of_node),fn(x)->GenServer.call({Integer.to_string(x)|>String.to_atom,Node.self()},{:complete,com,x},:infinity)end)
      :line->Enum.map(2..String.to_integer(number_of_node),fn(x)->GenServer.call({Integer.to_string(x)|>String.to_atom,Node.self()},{:line,x-1,x},:infinity)end)
             #this is for backward adding of the nodes
             Enum.map(1..(String.to_integer(number_of_node)-1),fn(x)->GenServer.call({Integer.to_string(x)|>String.to_atom,Node.self()},{:line,x+1,x},:infinity)end)
             #this is for forward adding of the terminal in the state of the GenServer
      :"2d"->
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
                    true->""
                  end
                end)
              end)
             end)
      :Im2d->
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
              true->""
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
          rand=number_of_node|>String.to_integer|>:rand.uniform
          GenServer.cast({rand|>Integer.to_string|>String.to_atom,Node.self()},{:msg,"hello",rand,type,4})
        "push-sum"->
          temp_val=
          case elem(List.to_tuple(args),1)|>String.to_atom do
            :full->number_of_node|>String.to_integer
            :line->number_of_node|>String.to_integer
            :"2d"->var*var
            :Im2d->var*var
          end
          Enum.map(1..temp_val,fn(x)->GenServer.call({x|>Integer.to_string|>String.to_atom,Node.self()},{:add_state,"",x},:infinity)end)
          rand=:rand.uniform(temp_val)
          GenServer.cast({rand|>Integer.to_string|>String.to_atom,Node.self()},{:msg,{},rand,type,0})
      end
    loop()
  end

  def handle_cast({:add_time,time},state) do
    {:noreply,Tuple.append(state,time)}
  end

  def handle_call({:add_val,name},_from,state) do
    map=Map.put(elem(state,1),name,1)
    state=Tuple.delete_at(state,1)
    state=Tuple.insert_at(state,1,map)
    if length(Map.to_list(elem(state,1)))==elem(state,0) do
      IO.puts(:os.system_time(:millisecond)-elem(state,2))
      Enum.map(1..elem(state,0),fn(x)->GenServer.stop({Integer.to_string(x)|>String.to_atom,Node.self()})end)
      Process.exit(self(),:normal)
    end
    {:reply,"",state}
  end

  def loop do
    Process.sleep(1_000_000)
    #loop
  end
end
