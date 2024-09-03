-- utils/data_validator.lua

local validator = {}

-- Validate if a value is in a given enumeration table
function validator.is_valid_enum_value(enum_table, value)
    for _, v in pairs(enum_table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Validate if a string is not empty
function validator.is_non_empty_string(value)
    return type(value) == "string" and value ~= ""
end

-- Validate if a number is within a specified range
function validator.is_within_range(value, min, max)
    return type(value) == "number" and value >= min and value <= max
end

-- Validate if a table is not empty
function validator.is_non_empty_table(value)
    return type(value) == "table" and next(value) ~= nil
end

-- Validate if a value is not nil
function validator.is_not_nil(value)
    return value ~= nil
end

-- Add more validation functions as needed

return validator
