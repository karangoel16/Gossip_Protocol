defmodule Project2 do
  use GenServer
  def start_link(args) do
    GenServer.start_link(__MODULE__,args,name: :Server)
  end
  def init(args) do
    {:ok,{args|>String.to_integer,%{}}}
  end

  def main(args\\[]) do
    if List.to_tuple(args)|>tuple_size<2 do
      IO.puts ("here")
      :init.stop()
    end
    number_of_node=elem(List.to_tuple(args),0)
    Project2.Exdistutils.start_distributed(:project2)
    start_link(number_of_node) #this is where the server genserver starts
    IO.puts "... build topology"
    GenServer.cast({:Server,Node.self()},{:add_time,:os.system_time(:millisecond)})
    IO.inspect Enum.map(1..String.to_integer(number_of_node),fn(x)->spawn(fn->Project2.Client.start_link(Integer.to_string(x)|>String.to_atom) end)end)
    
    case elem(List.to_tuple(args),1)|>String.to_atom do
      :full->Enum.map(1..String.to_integer(number_of_node),fn(x)->GenServer.call({Integer.to_string(x)|>String.to_atom,Node.self()},{:complete,number_of_node,x},:infinity)end)
      :line->Enum.map(2..String.to_integer(number_of_node),fn(x)->GenServer.call({Integer.to_string(x)|>String.to_atom,Node.self()},{:line,x-1,x},:infinity)end)
             #this is for backward adding of the nodes
             Enum.map(1..(String.to_integer(number_of_node)-1),fn(x)->GenServer.call({Integer.to_string(x)|>String.to_atom,Node.self()},{:line,x+1,x},:infinity)end)
             #this is for forward adding of the terminal in the state of the GenServer
      end
    GenServer.cast({:"3",Node.self()},{:msg,"hello",3})
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

  def spawnner(number_of_node,temp\\0) do
    IO.puts(temp)
    case String.to_integer(number_of_node)>temp do
      true->Process.spawn((fn->Project2.Client.start_link(Integer.to_string(temp)|>String.to_atom) end),[])
            spawnner(number_of_node,temp+1)
             {:ok}
      false->{:ok}
  end
  end

  def loop do
    Process.sleep(1_000_000)
    #loop
  end
end
