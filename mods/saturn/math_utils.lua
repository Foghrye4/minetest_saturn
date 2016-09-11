saturn.get_vector_pitch_angle = function(vector)
	local x=vector.x
	local y=vector.y
	local z=vector.z
	if y<=0 then
		return 3.141592654/2-(math.abs(math.asin(z))+math.abs(math.asin(x)))
	else
		return 3.141592654*3/2+(math.abs(math.asin(z))+math.abs(math.asin(x)))
	end
end

saturn.get_vector_yaw_angle = function(vector)
	local x=vector.x
	local y=vector.y
	local z=vector.z
	if z>=0 then
		return (math.acos(x/math.sqrt(x*x+z*z))-3.141592654/2)
	else
		return (-math.acos(x/math.sqrt(x*x+z*z))-3.141592654/2)
	end
end

saturn.vector_multiply = function(a,b)
	local c_x = a.y*b.z - b.y*a.z
	local c_y = b.x*a.z - a.x*b.z
	local c_z = a.x*b.y - b.x*a.y
	return vector.new(c_x,c_y,c_z)
end

saturn.sign_of_number = function(a)
	if a==0 then
		return 0
	elseif a<0 then
		return -1
	else
		return 1
	end
end

saturn.get_pseudogaussian_random = function(median, scale)
	return math.tan((math.random()-0.5)*math.pi)*scale+median
end

saturn.reduce_value_by_module = function(a)
	if a==0 then
		return 0
	elseif a<0 then
		return a+1
	else
		return a-1
	end
end
