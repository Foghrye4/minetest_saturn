if not math.pi then
	math.pi = 3.141592654
end

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

saturn.vector_to_matrix_multiply = function(vec,mat)
	return vector.new(
		vec.x*mat[1][1]+vec.y*mat[2][1]+vec.z*mat[3][1]+mat[4][1],
		vec.x*mat[1][2]+vec.y*mat[2][2]+vec.z*mat[3][2]+mat[4][2],
		vec.x*mat[1][3]+vec.y*mat[2][3]+vec.z*mat[3][3]+mat[4][3])
end

saturn.get_rotation_matrix_x = function(angle)
	return {
		{1, 0, 		     0, 	      0},
		{0, math.cos(angle), -math.sin(angle),0},
		{0, math.sin(angle), math.cos(angle), 0},
		{0, 0,		     0,		      1},
	}
end

saturn.get_rotation_matrix_y = function(angle)
	return {
		{math.cos(angle), 0, math.sin(angle), 0},
		{0, 		  1, 0,	  	      0},
		{-math.sin(angle),0, math.cos(angle), 0},
		{0,	  	  0, 0,		      1},
	}
end

saturn.get_rotation_matrix_z = function(angle)
	return {
		{math.cos(angle), -math.sin(angle), 0, 0},
		{math.sin(angle), math.cos(angle),  0, 0},
		{0,	    	  0,		    1, 0},
		{0,		  0,		    0, 1},
	}
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

saturn.is_inside_aabb = function(pos, minp, maxp)
    return minp.x <= pos.x and 
	minp.y <= pos.y and 
	minp.z <= pos.z and 
	maxp.x > pos.x and 
	maxp.y > pos.y and 
	maxp.z > pos.z
end

saturn.date_to_string = function(seconds)
	local hours = math.floor(seconds/3600)
	local minutes = math.floor((seconds-hours*3600)/60)
	return string.format ('%02d',hours)..":"..string.format ('%02d',minutes)..":"..string.format ('%02d',seconds-minutes*60-hours*3600)
end
