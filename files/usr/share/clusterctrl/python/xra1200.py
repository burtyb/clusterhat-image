import smbus

# Registers
# Direction
IN = 0x00
OUT = 0x01
DIR = 0x03
PUR = 0x04

INPUT = 1
OUTPUT = 0

class Xra1200():
	bus = -1
	address = -1
	port = -1

	def __init__(self,bus=0, address=0x39, port=0, dir="Null"):
		self.bus = smbus.SMBus(bus)
		self.address = address
		self.port = port
		if ( dir == 1 ):
			self.set_input()
		elif ( dir == 0 ):
			self.set_output()

	def set_dir(self, dir):
		self.bus.write_byte_data(self.address, DIR, dir)

	def get_dir(self):
		return self.bus.read_byte_data(self.address, DIR)
	
	def set_pur(self, pur):
		self.bus.write_byte_data(self.address, PUR, pur)

	def get_pur(self):
		try:
			reg = self.bus.read_byte_data(self.address, PUR)
		except IOError as err:
			return -1
		return reg

	def set_input(self):
		state = self.bus.read_byte_data(self.address, DIR)
		self.bus.write_byte_data(self.address, DIR, state | 1<<self.port)

	def write_byte(self, data):
		self.bus.write_byte_data(self.address,OUT, data)

	def read_byte(self):
		return self.bus.read_byte_data(self.address, IN)

	def on(self):
		state = self.bus.read_byte_data(self.address, OUT)
		self.bus.write_byte_data(self.address, OUT, state | 1<<self.port)

	def off(self):
		state = self.bus.read_byte_data(self.address, OUT)
		self.bus.write_byte_data(self.address, OUT, state & (255-(1<<self.port)))

	def get(self):
		state = self.bus.read_byte_data(self.address, IN)
		return ( ( state >> self.port) & 1 )
