import socket
from random import seed
from random import randint

#PMOD address and port
UDP_IP = "127.0.0.1"
UDP_PORT = 2233
print("PMOD IP:", UDP_IP)
print("PMOD port:", UDP_PORT)

#Device address and port
IP = "192.168.1.12"
PORT = 3030
DEVICE_IP = bytes.fromhex(''.join(format(int(x), '02x') for x in IP.split('.')))
DEVICE_PORT = bytes.fromhex(format(PORT, '04x'))

#create socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

#find mac address
mac = input("input mac address of device in \"xx-xx-xx-xx-xx-xx\" format (use ipconfig /all): ");

macBytes = bytes.fromhex(mac.replace('-',''))

print("To send UDP packet type: send IP PORT MESSAGE")
while True:
    #Take user input
    command, desIp, port, message = input().split()
    desIpBytes = bytes.fromhex(''.join(format(int(x), '02x') for x in desIp.split('.')))

    print("command:", command)
    print("ip:", desIp)
    print("port:", port)
    print("message:", message)

    length = len(message)
    if length < 18:
        fillSize = 18 - length
        #length = 18

    #Construct UDP packet
    etherHeader = B'\xFF\xFF\xFF\xFF\xFF\xFF' + macBytes +  B'\x08\x00'

	seed()
	value = randint(1, 65535)
    ipHeader = B'\x45\x00' + bytes.fromhex(format(28 + length, '04x')) + bytes([randint(0, 255), randint(0, 255)]) + B'\x00\x00\x80\x11\x00\x00' + DEVICE_IP + desIpBytes

	for i in range(8):
		


    udpHeader = DEVICE_PORT + bytes.fromhex(format(int(port), '04x')) + bytes.fromhex(format(8 + length, '04x')) + B'\x00\x00'

    filler = bytes(fillSize)

    packet = etherHeader + ipHeader + udpHeader + message.encode() + filler

    #send UDP packet
    print(''.join('\\x' + format(x, '02x') for x in packet))
	input();
    sock.sendto(packet, (UDP_IP, UDP_PORT))
