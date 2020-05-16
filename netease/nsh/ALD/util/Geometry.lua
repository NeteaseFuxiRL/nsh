--[=====[
Copyright (C) 2018--2020, 申瑞珉 (Ruimin Shen)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]=====]

local Class = {}
rawset(_G, 'ALD/util/Geometry', Class)

function Class.Create()
    return setmetatable({}, { __index = Class})
end

function Class.EuclideanDistance(p1, p2)
    assert(#p1 == #p2, string.format('%d, %d', #p1, #p2))
    local sum = 0
    for i, a in ipairs(p1) do
        local b = p2[i]
        local diff = a - b
        sum = sum + diff * diff
    end
    return math.sqrt(sum)
end

function Class.DirectionVector(p1, p2)
    local d = Class.EuclideanDistance(p1, p2)
    local v = {}
    if d == 0 then
        v[1] = 1
        for i = 2, #p1 do
            v[i] = 0
        end
    else
        for i, a in ipairs(p1) do
            local b = p2[i]
            v[i] = (b - a) / d
        end
    end
    return v
end

function Class.OrthogonalDirection(d1)
    assert(#d1 == 2)
    local alpha = math.atan2(d1[2], d1[1])
    local beta = alpha + math.pi / 2
    return {math.cos(beta), math.sin(beta)}
end

function Class.InnerProduct(v1, v2)
    assert(#v1 == #v2)
    local sum = 0
    for i, a in ipairs(v1) do
        local b = v2[i]
        sum = sum + a * b
    end
    return sum
end

function Class.VectorLength(v)
    local sum = 0
    for i, x in ipairs(v) do
        sum = sum + x * x
    end
    return math.sqrt(sum)
end

function Class.VectorAngle(v1, v2)
    return math.acos(Class.InnerProduct(v1, v2) / Class.VectorLength(v1) / Class.VectorLength(v2))
end

-- http://paulbourke.net/geometry/circlesphere/
function Class.IntersectionCircle2(x1, y1, r1, x2, y2, r2)
    local dx = x2 - x1
    local dy = y2 - y1
    local d = math.sqrt(dx * dx + dy * dy)
    local _d = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
    local _l = math.sqrt(r1 * r1 - _d * _d)
    local x = x1 + (_d * dx) / d
    local y = y1 + (_d * dy) / d
    local point1 = { x + (_l * dy) / d, y - (_l * dx) / d }
    local point2 = { x - (_l * dy) / d, y + (_l * dx) / d }
    local theta1 = math.atan2(point1[2]- y1, point1[1]- x1)
    local theta2 = math.atan2(point2[2]- y1, point2[1]- x1)
    if theta2 > theta1 then
        point1, point2 = point2, point1
    end
    return point1, point2
end

return Class
