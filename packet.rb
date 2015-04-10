class Packet
	@source 
	@id
	@seq
	@destination
	@payloadType
	@payload
	def initialize(src, dest, id, payloadType, payload)
		@source = src
		@destination = dest
		@id = id
		@payloadType = payloadType
		@payload = payload
	end
	def initialize(src, dest, id, seq, payloadType, payload)
		@source = src
		@destination = dest
		@id = id
		@seq = seq
		@payloadType = payloadType
		@payload = payload
	end

end