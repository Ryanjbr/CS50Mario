--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    -- initializes tileID variable, which isn't used yet.
    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    local keyset = math.random(4)

    local keySpawned = false;
    local lockSpawned = false;
    local hasKey = false

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        -- add x > 1 to ensure that emptiness never spawns at 1 (which is where player spawns)
        if math.random(7) == 1 and x > 1 then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            -- don't spawn any pillars at last column to make room for flag
            if math.random(8) == 1 and x ~= width then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false,
                            locked = false
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false,
                        locked = false
                    }
                )

                -- makes sure lock block spawns at least halfway through the level
            elseif math.random(24) == 1 and keySpawned == false or x > width - (width / 4) and keySpawned == false then
                table.insert(objects,
                    GameObject {
                        texture = 'keys-and-locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = keyset,
                        collidable = false,
                        consumable = true,

                        onConsume = function(player, obj) 
                            hasKey = true
                        end
                    })
                keySpawned = true
            end

            -- chance to spawn a block
            if math.random(10) == 1 then
                local lockBlock = false
                -- can't use conditionals in object initialization so declaring texture and frame here
                local t
                local f
                if math.random(10) == 1 and lockSpawned == false or x > width / 2 and lockSpawned == false then
                    print('lock spawn')
                    lockBlock = true
                    lockSpawned = true
                    t = 'keys-and-locks'
                    f = keyset + 4
                else
                    lockBlock = false
                    t = 'jump-blocks'
                    f = math.random(#JUMP_BLOCKS)
                end
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = t,
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        locked = lockBlock,

                        frame = f,
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit and not obj.locked then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            if obj.locked and hasKey then
                                -- spawn flag at end of level
                                local flagLocation = width - 1
                                table.insert(objects,
                                    GameObject {
                                        x = flagLocation * TILE_SIZE,
                                        y = 3 * TILE_SIZE,
                                        texture = 'poles',
                                        width = 16,
                                        height = 48,
                                        frame = POLES[math.random(#POLES)],
                                        solid = false,
                                        consumable = true,
                                        onConsume = function(player, obj)
                                            gStateMachine:change('play', {
                                                score = player.score,
                                                width = width + 25
                                            })
                                        end
                                    }
                                )
                                for k,v in pairs(objects) do
                                    if v == obj then
                                        table.remove(objects, k)
                                    end
                                end
                            end

                            gSounds['empty-block']:play()
                        end

                    }
                )
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end