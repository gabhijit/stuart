local class = require 'middleclass'
local socket = require 'socket'
local Receiver = require 'stuart.streaming.Receiver'

local SocketReceiver = class('SocketReceiver', Receiver)

function SocketReceiver:initialize(ssc, hostname, port)
  Receiver.initialize(self, ssc)
  self.hostname = hostname
  self.port = port or 0
end

function SocketReceiver:onStart()
  self.conn = socket.connect(self.hostname, self.port)
end

function SocketReceiver:onStop()
  if self.conn ~= nil then self.conn:close() end
end

function SocketReceiver:run(durationBudget)
  
  -- run loop. Read multiple lines until the duration budget has elapsed
  local timeOfLastYield = socket.gettime()
  local data = {}
  local minWait = 0.02 -- never block less than a 20ms "average context switch"
  while true do
    local elapsed = socket.gettime() - timeOfLastYield
    if elapsed > durationBudget then
      local rdd = self.ssc.sc:makeRDD(data)
      coroutine.yield({rdd})
      data = {}
      timeOfLastYield = socket.gettime()
    else
      self.conn:settimeout(math.max(minWait, durationBudget - elapsed))
      local line, err = self.conn:receive('*l')
      if not err then
        data[#data+1] = line
      end
    end
  end
  
end

return SocketReceiver
