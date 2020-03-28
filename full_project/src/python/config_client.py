import socket

BUFFER_SIZE = 1024
SERVER_ADDR = '192.168.1.10'
SERVER_PORT = 7

def get_str_addr(address):
    assert len(address) == 4
    str_addr = ""

    for i in range(4):
        str_addr += str(address[i])
        #if(i != 3):
        str_addr += "."
    return str_addr


# get the status of all ports
def get_status():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.connect((SERVER_ADDR, SERVER_PORT))
        sock.send(b'status')
        data = sock.recv(BUFFER_SIZE)
        print(data.decode("utf-8"))

# get the mappings of the IP address table
def list_ip_table():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.connect((SERVER_ADDR, SERVER_PORT))
        sock.send(b'iptable -l')
        data = sock.recv(BUFFER_SIZE)
        print(data.decode("utf-8"))
        #sock.send(b'POST' + bytes.fromhex('BAADF00D'))

# modify the IP address table
def update_ip_table(port, address):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.connect((SERVER_ADDR, SERVER_PORT))

        message = b'iptable -s' + b' ' + bytes(port, 'utf-8') + b' ' + bytes(get_str_addr(address), 'utf-8')
        sock.send(message)


if __name__ == '__main__':
    while(1):
        command = input("Enter a command: ")

        if(command.find("status") != -1):
            get_status()
        elif(command.find("iptable") != -1):
            command = command[command.find("iptable") + 8:]
            if(command.find("-s") != -1):
                command = command[command.find("-s") + 3:]
                com_split = command.split()
                if(len(com_split) == 2):
                    if(com_split[0] == "a" or com_split[0] == "b" or com_split[0] == "c"):
                        ip_split = com_split[1].split(".")

                        port = com_split[0]
                        address = []

                        if(len(ip_split) == 4):
                            err = 0

                            for i in ip_split:
                                if(not ((int(i) >= 0) and (int(i) < 256))):
                                    err = 1
                                    break
                                else:
                                    address.append(int(i))

                            if(not err):
                                #print(get_str_addr(address))
                                update_ip_table(port, address)
            elif(command.find("-l") != -1):
                list_ip_table()
