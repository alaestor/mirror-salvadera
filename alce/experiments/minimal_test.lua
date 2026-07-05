
local wrapper = {}
wrapper.f = function() print("hello") end
wrapper.foo = "bar"
print("wrapper.f exists:", wrapper.f ~= nil)
print("wrapper.foo is:", wrapper.foo)

if wrapper.foo == "bar" then
    print("SUCCESS!")
else
    print("FAILURE!")
end
