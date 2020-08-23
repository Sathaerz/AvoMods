function AsyncPirateGenerator:createScaledJammer(position)
    local scaling = self:getScaling()
    return self:create(position, 1.0 * scaling, "Jammer"%_T)
end

function AsyncPirateGenerator:createScaledScorcher(position)
    local scaling = self:getScaling()
    return self:create(position, 6.0 * scaling, "Scorcher"%_T)
end

function AsyncPirateGenerator:createScaledSinner(position)
    local scaling = self:getScaling()
    return self:create(position, 10.0 * scaling, "Sinner"%_T)
end

function AsyncPirateGenerator:createScaledProwler(position)
    local scaling = self:getScaling()
    return self:create(position, 12.0 * scaling, "Prowler"%_T)
end

function AsyncPirateGenerator:createScaledPillager(position)
    local scaling = self:getScaling()
    return self:create(position, 18.0 * scaling, "Pillager"%_T)
end

function AsyncPirateGenerator:createScaledDemolisher(position)
    local scaling = self:getScaling()
    return self:create(position, 28.0 * scaling, "Demolisher"%_T)
end

function AsyncPirateGenerator:createScaledPirateByName(name, position)
    return self["createScaled" .. name](self, position)
end

function AsyncPirateGenerator:createJammer(position)
    return self:create(position, 1.0, "Jammer"%_T)
end

function AsyncPirateGenerator:createScorcher(position)
    return self:create(position, 6.0, "Scorcher"%_T)
end

function AsyncPirateGenerator:createSinner(position)
    return self:create(position, 10.0, "Sinner"%_T)
end

function AsyncPirateGenerator.createProwler(position)
    return self:create(position, 12.0, "Prowler"%_T)
end

function AsyncPirateGenerator:createPillager(position)
    return self:create(position, 18.0, "Pillager"%_T)
end

function AsyncPirateGenerator:createDemolisher(position)
    return self:create(position, 28.0, "Demolisher"%_T)
end

function AsyncPirateGenerator:createPirateByName(name, position)
    return self["create" .. name](self, position)
end

--Get a number of positions for spawning pirates, so we don't need to do it in our missions / events.
function AsyncPirateGenerator:getStandardPositions(positionCT, distance)
    return PirateGenerator.getStandardPositions(positionCT, distance)
end