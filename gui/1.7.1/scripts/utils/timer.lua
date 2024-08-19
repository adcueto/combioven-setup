-- timer.lua

-- Definir la clase Timer
Timer = {}
Timer.__index = Timer

-- Constructor
function Timer:new(interval, callback)
    local obj = {
        interval = interval,
        callback = callback,
        timerID = nil,
        count = nil,
        onComplete = nil
    }
    setmetatable(obj, Timer)
    return obj
end

-- Método para iniciar el temporizador
function Timer:start(count)
    self.count = count or -1  -- Si count es nil, se repetirá indefinidamente
    self.timerID = gre.timer_set_interval(function() self:tick() end, self.interval)
end

-- Método para detener el temporizador
function Timer:stop()
    if self.timerID ~= nil then
        gre.timer_clear_interval(self.timerID)
        self.timerID = nil
    else
        print("Warning: Attempted to clear a nil timer ID")
    end
end

-- Método tick que se llama en cada intervalo
function Timer:tick()
    if self.count and self.count > 0 then
        self.count = self.count - 1
    elseif self.count == 0 then
        self:stop()
        if self.onComplete then
            self.onComplete()
        end
    end
    if self.callback then
        self.callback()
    end
end

-- Método para establecer la función de finalización
function Timer:setOnComplete(callback)
    self.onComplete = callback
end

return Timer


