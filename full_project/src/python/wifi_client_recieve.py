import socket

UDP_IP = "192.168.4.2"
UDP_PORT = 2233

print("PMOD IP:", UDP_IP)
print("PMOD port:", UDP_PORT)

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))

while True:
    data, addr = sock.recvfrom(256)
    data_str = data[42:].decode()
    print("received message:", data_str)
	