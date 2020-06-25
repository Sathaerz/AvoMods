function AsyncPirateGenerator:createScaledPillager(position)
    local scaling = self:getScaling()
    return self:create(position, 18.0 * scaling, "Pillager"%_T)
end

function AsyncPirateGenerator:createScaledConquistador(position)
    local scaling = self:getScaling()
    return self:create(position, 28.0 * scaling, "Conquistador"%_T)
end


function AsyncPirateGenerator:createPillager(position)
    return self:create(position, 18.0, "Pillager"%_T)
end

function AsyncPirateGenerator:createConquistador(position)
    return self:create(position, 28.0, "Conquistador"%_T)
end