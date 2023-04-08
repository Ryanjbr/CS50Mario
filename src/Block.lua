Block = Class{__includes = GameObject}

function Block:init(def)
    GameObject:init(self, def)
    self.locked = def.lockBlock
end

function Block:update() 
    GameObject:update()
end

function Block:render()
    GameObject:render()
end