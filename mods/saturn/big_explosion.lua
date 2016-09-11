local start_vectors = {}
local vectors = {}
local explosion_power_damping_factor = {}
local explosionPower = {}

local reduce_value_by_module = saturn.reduce_value_by_module
local addElement = function(coordinateKey, prev_pos, ix, iy, iz)
	vectors[coordinateKey] = {}
	local df = (prev_pos.x*prev_pos.x+prev_pos.y*prev_pos.y+prev_pos.z*prev_pos.z+1)/(ix*ix+iy*iy+iz*iz+1)
	explosion_power_damping_factor[coordinateKey] = df
end
local function precalculateExplosion()
	local maxExplosionRadius=32
	for levelRadius=1,maxExplosionRadius do
		for ix=-levelRadius,levelRadius do
			for iy=-levelRadius,levelRadius do
				for iz=-levelRadius,levelRadius do
					local prev_pos = {x=ix,y=iy,z=iz}
					local coordinatekey = minetest.hash_node_position(prev_pos) -- minetest.get_position_from_hash(hash)
					if(!vectors.containsKey(coordinateKey))
						if(math.abs(ix)+math.abs(iy)+math.abs(iz)>math.floor(levelRadius*1.8f)) then
							prev_pos.x=reduce_value_by_module(prev_pos.x)
							prev_pos.y=reduce_value_by_module(prev_pos.y)
							prev_pos.z=reduce_value_by_module(prev_pos.z)
						elseif(math.abs(ix)<=math.abs(iy) and math.abs(ix)<=math.abs(iz)) then
							prev_pos.y=reduce_value_by_module(prev_pos.y)
							prev_pos.z=reduce_value_by_module(prev_pos.z)
						elseif(math.abs(iy)<=math.abs(ix) and math.abs(iy)<=math.abs(iz)) then
							prev_pos.x=reduce_value_by_module(prev_pos.x)
							prev_pos.z=reduce_value_by_module(prev_pos.z)
						elseif(math.abs(iz)<=math.abs(ix) and math.abs(iz)<=math.abs(iy)) then
							prev_pos.y=reduce_value_by_module(prev_pos.y)
							prev_pos.x=reduce_value_by_module(prev_pos.x)
						end
						local prevKey = minetest.hash_node_position(prev_pos)
						if(prev_pos.x==ix and prev_pos.y==iy and prev_pos.z==iz and levelRadius>1)
							error("Variables are out of expected range. \n Expected are not equal: "..ix.."="..prev_pos.x.." "..iy.."="..prev_pos.y.." "..iz.."="..prev_pos.z)
						if levelRadius==1 then
							table.insert(start_vectors,coordinateKey)
							addElement(coordinateKey, prev_pos, ix, iy, iz)
						elseif vectors[prevKey] then
							table.insert(vectors[prevKey],coordinateKey)
							addElement(coordinateKey, prev_pos, ix, iy, iz)
						else
							error("ExplosionVector is missing parent! Help him!")
						end
					end
				end			
			end
		end
	end
end
	

local function setPower(Set<Long> sv2, power1) 
	for(long ev:sv2)
		this.setPower(ev, power1)
	end
end
		
	

local function setPower(Long ev, power1) 
	this.explosionPower.put(ev, power1)
end

local breakBlocksAndGetDescendants = function(explosion, longNumber)
	multiplier = exploder.multiplier
	int[] xyz = IHLUtils.decodeXYZ(longNumber)
	power1 = explosionPower.get(longNumber)
	if math.abs(xyz[0])>=math.abs(xyz[1]) and math.abs(xyz[0])>=math.abs(xyz[2])) then
		for(ix=xyz[0]>0?0:multiplier-1ix<multiplier and ix>=0ix=xyz[0]>0?ix+1:ix-1)
			for(iy=xyz[1]>0?0:multiplier-1iy<multiplier and iy>=0iy=xyz[1]>0?iy+1:iy-1)
				for(iz=xyz[2]>0?0:multiplier-1iz<multiplier and iz>=0iz=xyz[2]>0?iz+1:iz-1)
					power1 = this.getNewPowerAndProcessBlocks(world, exploder, explosion, xyz, multiplier, ix, iy, iz, power1)
		else if(math.abs(xyz[1])>=math.abs(xyz[0]) and math.abs(xyz[1])>=math.abs(xyz[2]))
			for(iy=xyz[1]>0?0:multiplier-1iy<multiplier and iy>=0iy=xyz[1]>0?iy+1:iy-1)
				for(ix=xyz[0]>0?0:multiplier-1ix<multiplier and ix>=0ix=xyz[0]>0?ix+1:ix-1)
					for(iz=xyz[2]>0?0:multiplier-1iz<multiplier and iz>=0iz=xyz[2]>0?iz+1:iz-1)
						power1 = this.getNewPowerAndProcessBlocks(world, exploder, explosion, xyz, multiplier, ix, iy, iz, power1)
		else
			for(iz=xyz[2]>0?0:multiplier-1iz<multiplier and iz>=0iz=xyz[2]>0?iz+1:iz-1)
				for(ix=xyz[0]>0?0:multiplier-1ix<multiplier and ix>=0ix=xyz[0]>0?ix+1:ix-1)
					for(iy=xyz[1]>0?0:multiplier-1iy<multiplier and iy>=0iy=xyz[1]>0?iy+1:iy-1)
						power1 = this.getNewPowerAndProcessBlocks(world, exploder, explosion, xyz, multiplier, ix, iy, iz, power1)
		power1=math.round(power1*explosion_power_damping_factor.get(longNumber)-0.5f)
		if(power1<=1 || !vectors.containsKey(longNumber)|| vectors.get(longNumber).isEmpty())
			exploder.effectBorderBlocks.add(longNumber)
			if(xyz[1]<0 || (exploder.y<=6 and xyz[1]<=6))
				exploder.effectBorderBlocksWithLowPosition.add(longNumber)
			return nil
		else
			for(long d1:vectors.get(longNumber))
				explosionPower.put(d1, power1)
			return vectors.get(longNumber)
		end
	end
end

local get_new_power_and_process_node = function(exploder, xyz, multiplier, ix, iy, iz, power2)
		local power1=power2
		local x = exploder.x+xyz.x*multiplier+ix
		local y = exploder.y+xyz.y*multiplier+iy
		local z = exploder.z+xyz.z*multiplier+iz
		local node = minetest.get_node(vector.new(x,y,z))
		local explosionResistance = math.round(block.getExplosionResistance(exploder, world, x, y, z, exploder.x, exploder.y, exploder.z)*10f)
		if explosionResistance>=power1 then
			power1=0
		else
			power1-=math.round(block.getExplosionResistance(exploder, world, x, y, z, exploder.x, exploder.y, exploder.z)*10f)
			Entity entity = exploder.getEntity(x, y, z)
			if(entity!=null)
			
				entity.attackEntityFrom(exploder.damageSource, power1/10f)
			
			block.onBlockDestroyedByExplosion(world, x, y, z, explosion)
			exploder.setBlockToAir(x, y, z)
		end
		return power1
end
